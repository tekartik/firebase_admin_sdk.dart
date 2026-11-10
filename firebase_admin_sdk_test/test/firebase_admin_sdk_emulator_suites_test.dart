/// The shared auth and firestore suites on the admin sdk, against the auth
/// and firestore emulators.
///
/// The emulator hosts must be in the process environment: a test body run by
/// `dart test` does not run in the zone of its declaration, and the firestore
/// client (google_cloud_firestore) reads its own zone key, not the admin sdk
/// one. Without them the suites would reach the real project of the
/// credentials, so the file is skipped. Run it with (needs
/// `emulator/.firebaserc`, Java for the firestore emulator):
///
///     FIREBASE_AUTH_EMULATOR_HOST=127.0.0.1:9099 \
///     FIRESTORE_EMULATOR_HOST=127.0.0.1:8080 \
///       dart test test/firebase_admin_sdk_emulator_suites_test.dart
@TestOn('vm')
library;

import 'dart:io';

import 'package:tekartik_firebase_admin_sdk/firebase_admin_sdk.dart';
import 'package:tekartik_firebase_admin_sdk/firebase_auth_admin_sdk.dart';
import 'package:tekartik_firebase_admin_sdk/firestore_admin_sdk.dart';
import 'package:tekartik_firebase_auth/auth_admin.dart';
import 'package:tekartik_firebase_auth_test/auth_admin_test_runner.dart';
import 'package:tekartik_firebase_auth_test/auth_test.dart'
    show runAuthAppTests;
import 'package:tekartik_firebase_emulator/firebase_emulator.dart';
import 'package:tekartik_firebase_firestore_test/firestore_test_runner.dart'
    show runFirestoreTests, skipConcurrentTransactionTests;
import 'package:test/test.dart';

/// Needs `emulator/.firebaserc` (git ignored), skipped otherwise.
var _emulatorService = FirebaseEmulatorService(path: 'emulator');

/// The emulator hosts, see `emulator/firebase.json`.
const _authEmulatorHost = '127.0.0.1:9099';
const _firestoreEmulatorHost = '127.0.0.1:8080';

/// A demo project: the emulators never reach a real project for it.
const _projectId = 'demo-tekartik-admin-sdk-test';

Future<void> main() async {
  var environment = Platform.environment;
  if (environment['FIREBASE_AUTH_EMULATOR_HOST'] != _authEmulatorHost ||
      environment['FIRESTORE_EMULATOR_HOST'] != _firestoreEmulatorHost) {
    test(
      'not_supported',
      () {},
      skip:
          'needs FIREBASE_AUTH_EMULATOR_HOST=$_authEmulatorHost and '
          'FIRESTORE_EMULATOR_HOST=$_firestoreEmulatorHost',
    );
    return;
  }
  if (!await _emulatorService.isSupported()) {
    test('not_supported', () {}, skip: 'firebase emulator is not supported');
    return;
  }

  // The emulator locks a document read in a transaction: the write outside
  // of it waits for the lock (as on the REST emulator runs).
  skipConcurrentTransactionTests = true;

  late FirebaseEmulator emulator;
  // Created now (no request is sent): the suites need it when declared.
  var app = firebaseAdminSdk.initializeApp(
    options: FirebaseAppOptions(projectId: _projectId),
    name: 'emulator_suites',
  );
  var auth = firebaseAuthServiceAdminSdk.auth(app) as FirebaseAuthAdmin;

  group('admin_sdk_emulator_suites', () {
    setUpAll(() async {
      emulator = await _emulatorService.start(
        options: FirebaseEmulatorOptions(
          projectId: _projectId,
          onlyAuth: true,
          onlyFirestore: true,
          debug: false,
        ),
      );
    });

    tearDownAll(() async {
      await app.delete();
      await emulator.stop();
    });

    group('auth', () {
      runAuthAppTests(authService: firebaseAuthServiceAdminSdk, app: app);
      // No current user on the admin sdk: the sign in checks are skipped.
      firebaseAuthAdminTests(
        getAuth: () => auth,
        email: 'auth_admin_tests@example.com',
        password: 'password1',
      );
    });

    group('firestore', () {
      runFirestoreTests(
        firebase: firebaseAdminSdk,
        firestoreService: firestoreServiceAdminSdk,
        options: AppOptions(projectId: _projectId),
      );
    });
  }, timeout: const Timeout(Duration(minutes: 5)));
}
