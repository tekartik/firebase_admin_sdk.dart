@TestOn('vm')
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;

// The zone environment key of the admin sdk (internal, used by its tests).
// ignore: implementation_imports, invalid_use_of_internal_member
import 'package:firebase_admin_sdk/src/app.dart' as admin_sdk show envSymbol;
import 'package:google_cloud_firestore/google_cloud_firestore.dart' as gcf;
import 'package:tekartik_firebase_admin_sdk/firebase_admin_sdk.dart';
import 'package:tekartik_firebase_admin_sdk/firebase_auth_admin_sdk.dart';
import 'package:tekartik_firebase_admin_sdk/firestore_admin_sdk.dart';
import 'package:tekartik_firebase_auth/auth_admin.dart';
import 'package:test/test.dart';

/// The email and uid of an account that exists on the fake emulator.
const _existingEmail = 'exists@example.com';
const _existingUid = 'existing_uid';

/// A fake Firestore and Auth emulator recording the requests.
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
      Object? responseBody;
      var statusCode = 200;
      var bodyMap = requests.last.$2;
      if (path.contains('identitytoolkit') &&
          (bodyMap['email'] == _existingEmail ||
              bodyMap['localId'] == _existingUid)) {
        // An existing account, as the auth emulator answers it.
        statusCode = 400;
        var message = bodyMap['email'] == _existingEmail
            ? 'EMAIL_EXISTS'
            : 'DUPLICATE_LOCAL_ID';
        responseBody = {
          'error': {
            'code': 400,
            'message': message,
            'errors': [
              {'message': message, 'reason': 'invalid', 'domain': 'global'},
            ],
          },
        };
      } else if (path.contains('identitytoolkit')) {
        // Auth emulator: an account creation answers its uid, a lookup the
        // created user.
        responseBody = path.endsWith(':lookup')
            ? {
                'users': [
                  {
                    'localId': 'created_uid',
                    'email': 'bob@example.com',
                    'createdAt': '1760313600000',
                  },
                ],
              }
            : {'localId': 'created_uid'};
      } else {
        responseBody = path.endsWith(':runQuery')
            ? [
                {'readTime': '2026-10-13T00:00:00Z'},
              ]
            : {
                'commitTime': '2026-10-13T00:00:00Z',
                'writeResults': [<String, Object?>{}],
              };
      }
      request.response
        ..statusCode = statusCode
        ..headers.contentType = io.ContentType.json
        ..write(jsonEncode(responseBody));
      await request.response.close();
    });
  }

  /// The emulator environment.
  Map<String, String> get _environment => {
    'FIRESTORE_EMULATOR_HOST': '127.0.0.1:${server.port}',
    'FIREBASE_AUTH_EMULATOR_HOST': '127.0.0.1:${server.port}',
    'GCLOUD_PROJECT': 'demo-offline',
  };

  /// Runs [body] with the admin sdk pointing to this emulator.
  Future<T> run<T>(Future<T> Function() body) => runZoned(
    body,
    // The sdk zone environments (meant for their tests), so that the emulator
    // hosts are set for this zone only: the firestore one and the admin sdk
    // one (auth). Two private symbols of the same name (distinct at runtime,
    // equal for the analyzer, hence no map literal).
    zoneValues: <Object?, Object?>{}
      // ignore: invalid_use_of_internal_member
      ..[gcf.envSymbol] = _environment
      // ignore: invalid_use_of_internal_member
      ..[admin_sdk.envSymbol] = _environment,
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

    /// The cursor values sent for [query] (`startAt` of the structured query).
    Future<Object?> startAtSent(Query query) async {
      emulator.requests.clear();
      await query.get();
      var runQuery = emulator.requests.firstWhere((r) => r.$1 == 'runQuery');
      return (runQuery.$2['structuredQuery'] as Map)['startAt'];
    }

    test('cursor with fewer values than order bys, null value', () async {
      await withFirestore((firestore) async {
        // Firestore compares the given values only (a prefix).
        var startAt = jsonEncode(
          await startAtSent(
            firestore
                .collection('c')
                .orderBy('a')
                .orderById()
                .startAt(values: [2]),
          ),
        );
        expect(startAt, contains('"integerValue":"2"'));
        expect(startAt, isNot(contains('referenceValue')));

        // A null cursor value (null sorts first).
        startAt = jsonEncode(
          await startAtSent(
            firestore.collection('c').orderBy('a').startAfter(values: [null]),
          ),
        );
        expect(startAt, contains('nullValue'));
      });
    });
  });

  test('auth createUser sends every field of the request', () async {
    await emulator.run(() async {
      var app = firebaseAdminSdk.initializeApp(
        options: AppOptions(projectId: 'demo-offline'),
        name: 'offline_${++_appIndex}',
      );
      try {
        var auth = firebaseAuthServiceAdminSdk.auth(app) as FirebaseAuthAdmin;
        emulator.requests.clear();
        var record = await auth.createUser(
          FirebaseAuthCreateUserRequest(
            email: 'bob@example.com',
            password: 'password1',
            displayName: 'Bob',
            emailVerified: true,
            phoneNumber: '+33600000000',
            photoURL: 'https://example.com/bob.png',
          ),
        );
        expect(record.uid, 'created_uid');
        // The account creation request.
        var signUp = emulator.requests.first.$2;
        expect(signUp['email'], 'bob@example.com');
        expect(signUp['displayName'], 'Bob');
        expect(signUp['emailVerified'], isTrue);
        expect(signUp['phoneNumber'], '+33600000000');
        expect(signUp['photoUrl'], 'https://example.com/bob.png');
      } finally {
        await app.delete();
      }
    });
  });

  test(
    'auth createUser of an existing email or uid throws a StateError',
    () async {
      // As the other admin backends (auth_sembast, auth_sdb, auth_local) and
      // the shared firebaseAuthAdminTests: not the native exception.
      await emulator.run(() async {
        var app = firebaseAdminSdk.initializeApp(
          options: AppOptions(projectId: 'demo-offline'),
          name: 'offline_${++_appIndex}',
        );
        try {
          var auth = firebaseAuthServiceAdminSdk.auth(app) as FirebaseAuthAdmin;
          await expectLater(
            auth.createUser(
              FirebaseAuthCreateUserRequest(email: _existingEmail),
            ),
            throwsA(
              isA<StateError>().having(
                (e) => e.message,
                'message',
                contains('email-already-exists'),
              ),
            ),
          );
          await expectLater(
            auth.createUser(FirebaseAuthCreateUserRequest(uid: _existingUid)),
            throwsA(
              isA<StateError>().having(
                (e) => e.message,
                'message',
                contains('uid-already-exists'),
              ),
            ),
          );
          await expectLater(
            auth.createUserWithEmailAndPassword(
              email: _existingEmail,
              password: 'password1',
            ),
            throwsA(isA<StateError>()),
          );
        } finally {
          await app.delete();
        }
      });
    },
  );

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
