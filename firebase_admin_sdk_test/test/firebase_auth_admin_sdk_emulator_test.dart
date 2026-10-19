@TestOn('vm')
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

// The zone environment key of the sdk (internal, used by its own tests): the
// only way to point the auth at the emulator without setting the process
// environment before the test starts.
// ignore: implementation_imports, invalid_use_of_internal_member
import 'package:firebase_admin_sdk/src/app.dart' show envSymbol;
import 'package:http/http.dart' as http;
import 'package:tekartik_firebase_admin_sdk/firebase_admin_sdk.dart';
import 'package:tekartik_firebase_admin_sdk/firebase_auth_admin_sdk.dart';
import 'package:tekartik_firebase_auth/auth_admin.dart';
import 'package:tekartik_firebase_emulator/firebase_emulator.dart';
import 'package:test/test.dart';

/// Needs `emulator/.firebaserc` (git ignored), skipped otherwise.
var _emulatorService = FirebaseEmulatorService(path: 'emulator');

/// The auth emulator host, see `emulator/firebase.json`.
const _authEmulatorHost = '127.0.0.1:9099';

/// Runs [action] with the auth emulator environment: the sdk reads it when a
/// call is made (token verification, requests).
Future<T> _inEmulator<T>(Future<T> Function() action) => runZoned(
  action,
  zoneValues: {
    // ignore: invalid_use_of_internal_member
    envSymbol: {
      ...Platform.environment,
      'FIREBASE_AUTH_EMULATOR_HOST': _authEmulatorHost,
    },
  },
);

/// A user signed up on the emulator as a client would (REST), anonymous
/// without [email].
Future<({String uid, String idToken, String refreshToken})> _signUp({
  String? email,
  String? password,
}) async {
  var response = await http.post(
    Uri.parse(
      'http://$_authEmulatorHost/identitytoolkit.googleapis.com/v1/'
      'accounts:signUp?key=dummy',
    ),
    headers: {'content-type': 'application/json'},
    body: jsonEncode({
      'email': ?email,
      'password': ?password,
      'returnSecureToken': true,
    }),
  );
  expect(response.statusCode, 200, reason: response.body);
  var map = jsonDecode(response.body) as Map;
  return (
    uid: map['localId'] as String,
    idToken: map['idToken'] as String,
    refreshToken: map['refreshToken'] as String,
  );
}

/// Refreshes the id token as a client would, setting the user
/// lastRefreshTime.
Future<void> _refreshIdToken(String refreshToken) async {
  var response = await http.post(
    Uri.parse(
      'http://$_authEmulatorHost/securetoken.googleapis.com/v1/token'
      '?key=dummy',
    ),
    headers: {'content-type': 'application/json'},
    body: jsonEncode({
      'grant_type': 'refresh_token',
      'refresh_token': refreshToken,
    }),
  );
  expect(response.statusCode, 200, reason: response.body);
}

Future<void> main() async {
  if (!await _emulatorService.isSupported()) {
    test('not_supported', () {}, skip: 'firebase emulator is not supported');
    return;
  }

  final projectId = await _emulatorService.getProjectId();
  late FirebaseEmulator emulator;
  late FirebaseApp app;
  late FirebaseAuthAdmin auth;

  group('auth_admin_sdk_emulator', () {
    setUpAll(() async {
      emulator = await _emulatorService.start(
        options: FirebaseEmulatorOptions(
          projectId: projectId,
          onlyAuth: true,
          debug: false,
        ),
      );
      app = firebaseAdminSdk.initializeApp(
        options: FirebaseAppOptions(projectId: projectId),
        name: 'auth_emulator',
      );
      auth = firebaseAuthServiceAdminSdk.auth(app) as FirebaseAuthAdmin;
    });

    tearDownAll(() async {
      await app.delete();
      await emulator.stop();
    });

    test('verifyIdToken anonymous', () async {
      await _inEmulator(() async {
        var user = await _signUp();
        var decoded = await auth.verifyIdToken(user.idToken);
        expect(decoded.uid, user.uid);
        expect(decoded.signInProvider, firebaseAuthAnonymousProviderId);
        decoded = await auth.verifyIdToken(user.idToken, checkRevoked: true);
        expect(decoded.uid, user.uid);

        // Revoked once the user is deleted (the emulator always checks).
        await auth.deleteUser(user.uid);
        expect(await auth.getUser(user.uid), isNull);
        await expectLater(
          auth.verifyIdToken(user.idToken, checkRevoked: true),
          throwsA(anything),
        );
      });
    });

    test('verifyIdToken password', () async {
      await _inEmulator(() async {
        var user = await _signUp(
          email: 'verify_id_token@example.com',
          password: 'password1',
        );
        try {
          var decoded = await auth.verifyIdToken(user.idToken);
          expect(decoded.uid, user.uid);
          expect(decoded.signInProvider, firebaseAuthEmailPasswordProviderId);
        } finally {
          await auth.deleteUser(user.uid);
        }
      });
    });

    test('verifyIdToken invalid', () async {
      await _inEmulator(() async {
        await expectLater(
          auth.verifyIdToken('not_an_id_token'),
          throwsA(anything),
        );
      });
    });

    test('metadata lastRefreshTime', () async {
      await _inEmulator(() async {
        var user = await _signUp();
        try {
          await _refreshIdToken(user.refreshToken);
          var metadata = (await auth.getUser(user.uid))!.metadata!;
          expect(DateTime.parse(metadata.creationTime).isUtc, isTrue);
          expect(metadata.lastSignInTime, isNotEmpty);
          expect(DateTime.parse(metadata.lastRefreshTime!).isUtc, isTrue);
        } finally {
          await auth.deleteUser(user.uid);
        }
      });
    });
  }, timeout: const Timeout(Duration(minutes: 5)));
}
