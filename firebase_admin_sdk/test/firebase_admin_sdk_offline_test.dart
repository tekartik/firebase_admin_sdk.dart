@TestOn('vm')
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;

import 'package:google_cloud_firestore/google_cloud_firestore.dart' as gcf;
import 'package:tekartik_firebase_admin_sdk/firebase_admin_sdk.dart';
import 'package:tekartik_firebase_admin_sdk/firebase_auth_admin_sdk.dart';
import 'package:tekartik_firebase_admin_sdk/firestore_admin_sdk.dart';
import 'package:test/test.dart';

/// A fake Firestore emulator recording the requests.
class _FakeEmulator {
  late final io.HttpServer server;
  final requests = <(String, Map<String, Object?>)>[];

  Future<void> start() async {
    server = await io.HttpServer.bind(io.InternetAddress.loopbackIPv4, 0);
    server.listen((request) async {
      var body = await utf8.decoder.bind(request).join();
      var path = request.uri.path;
      requests.add((
        path.split(':').last,
        body.isEmpty
            ? <String, Object?>{}
            : jsonDecode(body) as Map<String, Object?>,
      ));
      request.response
        ..statusCode = 200
        ..headers.contentType = io.ContentType.json
        ..write(
          jsonEncode(
            path.endsWith(':runQuery')
                ? [
                    {'readTime': '2026-10-13T00:00:00Z'},
                  ]
                : {
                    'commitTime': '2026-10-13T00:00:00Z',
                    'writeResults': [<String, Object?>{}],
                  },
          ),
        );
      await request.response.close();
    });
  }

  /// Runs [body] with the admin sdk pointing to this emulator.
  Future<T> run<T>(Future<T> Function() body) => runZoned(
    body,
    zoneValues: {
      // The sdk zone environment (meant for its tests), so that the emulator
      // host is set for this zone only.
      // ignore: invalid_use_of_internal_member
      gcf.envSymbol: {
        'FIRESTORE_EMULATOR_HOST': '127.0.0.1:${server.port}',
        'GCLOUD_PROJECT': 'demo-offline',
      },
    },
  );
}

var _appIndex = 0;

void main() {
  late _FakeEmulator emulator;
  setUpAll(() async {
    emulator = _FakeEmulator();
    await emulator.start();
  });
  tearDownAll(() => emulator.server.close(force: true));

  Future<T> withFirestore<T>(Future<T> Function(Firestore firestore) body) =>
      emulator.run(() async {
        var app = firebaseAdminSdk.initializeApp(
          options: AppOptions(projectId: 'demo-offline'),
          name: 'offline_${++_appIndex}',
        );
        try {
          return await body(firestoreServiceAdminSdk.firestore(app));
        } finally {
          await app.delete();
        }
      });

  /// The structured query `where` sent for [query].
  Future<Object?> whereSent(Query query) async {
    emulator.requests.clear();
    await query.get();
    var runQuery = emulator.requests.firstWhere((r) => r.$1 == 'runQuery');
    return (runQuery.$2['structuredQuery'] as Map)['where'];
  }

  group('firestore', () {
    test('where with several conditions sends every condition', () async {
      await withFirestore((firestore) async {
        var where = jsonEncode(
          await whereSent(
            firestore
                .collection('c')
                .where('x', isGreaterThan: 1, isLessThan: 5),
          ),
        );
        expect(where, contains('GREATER_THAN'));
        expect(where, contains('LESS_THAN'));
      });
    });

    test('where isNull', () async {
      await withFirestore((firestore) async {
        expect(
          jsonEncode(
            await whereSent(
              firestore.collection('c').where('x', isNull: false),
            ),
          ),
          contains('IS_NOT_NULL'),
        );
        var isNullWhere = jsonEncode(
          await whereSent(firestore.collection('c').where('x', isNull: true)),
        );
        expect(isNullWhere, contains('IS_NULL'));
        expect(isNullWhere, isNot(contains('IS_NOT_NULL')));
      });
    });

    test('arrayUnion/arrayRemove convert their elements', () async {
      await withFirestore((firestore) async {
        emulator.requests.clear();
        await firestore.doc('c/d').update({
          'a': FieldValue.arrayUnion([Timestamp(1, 0), firestore.doc('c/e')]),
          'b': FieldValue.arrayRemove([Timestamp(2, 0)]),
        });
        var commit = jsonEncode(
          emulator.requests.firstWhere((r) => r.$1 == 'commit').$2,
        );
        expect(commit, contains('timestampValue'));
        expect(commit, contains('referenceValue'));
      });
    });
  });

  test('firebaseAdminSdk is a single instance', () async {
    expect(identical(firebaseAdminSdk, firebaseAdminSdk), isTrue);
    var app = firebaseAdminSdk.initializeApp(
      options: AppOptions(projectId: 'demo-offline'),
      name: 'offline_single',
    );
    try {
      expect(firebaseAdminSdk.app(name: 'offline_single'), app);
    } finally {
      await app.delete();
    }
  });

  test('auth onCurrentUser emits null', () async {
    var app = firebaseAdminSdk.initializeApp(
      options: AppOptions(projectId: 'demo-offline'),
      name: 'offline_auth',
    );
    try {
      var auth = firebaseAuthServiceAdminSdk.auth(app);
      expect(
        await auth.onCurrentUser.first.timeout(const Duration(seconds: 5)),
        isNull,
      );
    } finally {
      await app.delete();
    }
  });
}
