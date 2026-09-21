---
name: tekartik-firebase-admin-sdk-test-setup
description: >-
  Use when running or adding the shared tekartik firebase test suites against
  the admin sdk implementation (tekartik_firebase_admin_sdk):
  tekartik_firebase_admin_sdk_test, runFirebaseTests, runFirestoreTests,
  runAuthTests, runStorageTests, firebaseAuthAdminTests, TestStorageOptions,
  firebaseAdminSdk, firestoreServiceAdminSdk, firebaseAuthServiceAdminSdk,
  firebaseStorageServiceAdminSdk, and the emulator variables
  FIRESTORE_EMULATOR_HOST / FIREBASE_AUTH_EMULATOR_HOST / PUBSUB_EMULATOR_HOST.
---

# Shared test suites for the admin sdk (tekartik_firebase_admin_sdk_test)

A test-only package: it has **no `lib/`**, only `test/`. It exists to run the
cross-implementation suites of `tekartik_firebase_test`,
`tekartik_firebase_firestore_test`, `tekartik_firebase_auth_test` and
`tekartik_firebase_storage_test` against `tekartik_firebase_admin_sdk`, plus a
raw test of the native `firebase_admin_sdk` app lifecycle.

## Guidelines

* Nothing to import from this package. To reproduce the same setup in your own
  project, add the abstraction test packages as dev dependencies (all git, none
  on pub.dev):

  ```yaml
  dev_dependencies:
    tekartik_firebase_test:
      git:
        url: https://github.com/tekartik/firebase.dart
        path: firebase_test
    tekartik_firebase_firestore_test:
      git:
        url: https://github.com/tekartik/firebase_firestore.dart
        path: firestore_test
    tekartik_firebase_auth_test:
      git:
        url: https://github.com/tekartik/firebase_auth.dart
        path: auth_test
    tekartik_firebase_storage_test:
      git:
        url: https://github.com/tekartik/firebase_storage.dart
        path: storage_test
  ```

  The package under test itself:

  ```yaml
  dependencies:
    tekartik_firebase_admin_sdk:
      git:
        url: https://github.com/tekartik/firebase_admin_sdk.dart
        path: firebase_admin_sdk
  ```

* Entry points and what they need:
  - `runFirebaseTests(firebaseAsync, {options, name})` — positional
    `FirebaseAsync`, i.e. `firebaseAdminSdk`. Exercises app creation/deletion
    only, so it runs with no credentials.
  - `runFirestoreTests(firebase:, firestoreService:, options:, testContext:)`.
  - `runAuthTests(firebase:, authService:, options:, name:)` and, from
    `auth_admin_test_runner.dart`,
    `firebaseAuthAdminTests(getAuth:, email:, password:)` which takes a
    `FirebaseAuthAdmin` (cast `firebaseAuthServiceAdminSdk.auth(app)`).
  - `runStorageTests(firebase:, storageService:, options:, storageOptions:)`
    with `TestStorageOptions(bucket:, rootPath:, skipDefaultBucketExists:)`.

  All of them create and delete the app themselves in `setUpAll`/`tearDownAll`;
  do not initialize one around them.

* Every suite but `runFirebaseTests` talks to a backend. Point them at the
  emulators before `dart test`: `FIRESTORE_EMULATOR_HOST=localhost:8080`,
  `FIREBASE_AUTH_EMULATOR_HOST=localhost:9099`,
  `FIREBASE_STORAGE_EMULATOR_HOST=localhost:9199`,
  `CLOUD_TASKS_EMULATOR_HOST`, `PUBSUB_EMULATOR_HOST=localhost:8085`, with
  `AppOptions(projectId: 'demo-xxx')` so no credentials are needed. Against a
  real project export `GOOGLE_APPLICATION_CREDENTIALS` instead, and use a
  throw-away project: the suites write and delete documents, users and files.

* That is why `test/firestore_admin_sdk_test.dart` and
  `test/firebase_storage_admin_sdk_test.dart` in this package pass
  `skip: true` to their top level `group`. Keep that pattern (or a
  `dart_test.yaml` tag) for suites that need a live backend, so `dart test`
  stays green offline.

* Expect capability failures, not bugs, when a suite is too broad for the admin
  sdk: `FirestoreService.supportsTrackChanges` and `supportsAggregateQueries`
  are `false` (`onSnapshot`, `documentChanges` and `aggregate` throw), and
  `FirebaseAuth.supportsCurrentUser` is `false` (no sign in — use the admin
  runner, not the sign in one). Check the `supportsXxx` flags in a test rather
  than skipping blindly.

* `firebaseAdminSdk` is a process-wide singleton and the native sdk throws when
  the same app name is initialized twice with different options: give each
  group its own `name:`, or reuse the default app and `await app.delete()` in
  `tearDownAll`. `test/firebase_admin_sdk_raw_test.dart` shows the native side
  (`FirebaseApp.initializeApp()`, `FirebaseApp.apps`, `FirebaseApp.deleteApp`,
  `wasInitializedFromEnv`) and cleans up with
  `FirebaseApp.apps.forEach(FirebaseApp.deleteApp)` in `tearDown`.

* Run everything with `dart test` from the package directory (the repo is a pub
  workspace, so `dart pub get` at the repo root resolves it).

## Examples

### Firebase level suite plus admin sdk specific checks

```dart
import 'package:tekartik_firebase/firebase_mixin.dart';
import 'package:tekartik_firebase_admin_sdk/firebase_admin_sdk.dart';
import 'package:tekartik_firebase_test/firebase_test.dart';
import 'package:test/test.dart';

void main() {
  group('admin_sdk', () {
    var firebase = firebaseAdminSdk;
    group('firebase', () {
      runFirebaseTests(firebase, options: null);
      runFirebaseTests(
        firebase,
        options: AppOptions(projectId: 'test'),
        name: 'test',
      );
    });

    test('isLocal', () {
      expect(firebase.isLocal, isFalse);
    });

    test('projectId', () async {
      FirebaseMixin.latestFirebaseInstanceOrNull = null;
      var app = await firebase.initializeAppAsync(
        options: AppOptions(projectId: 'test'),
      );
      expect(app.options.projectId, 'test');
      expect(app.hasAdminCredentials, isTrue);
      await app.delete();
    });
  });
}
```

### Firestore suite against the emulator

```dart
@TestOn('vm')
library;

import 'dart:io';

import 'package:tekartik_firebase_admin_sdk/firebase_admin_sdk.dart';
import 'package:tekartik_firebase_admin_sdk/firestore_admin_sdk.dart';
import 'package:tekartik_firebase_firestore_test/firestore_test_runner.dart';
import 'package:test/test.dart';

/// Run with FIRESTORE_EMULATOR_HOST=localhost:8080 exported.
void main() {
  var hasEmulator =
      Platform.environment['FIRESTORE_EMULATOR_HOST']?.isNotEmpty ?? false;
  group(
    'firestore_admin_sdk',
    () {
      test('supports', () {
        expect(firestoreServiceAdminSdk.supportsTrackChanges, isFalse);
        expect(firestoreServiceAdminSdk.supportsAggregateQueries, isFalse);
      });
      runFirestoreTests(
        firebase: firebaseAdminSdk,
        firestoreService: firestoreServiceAdminSdk,
        options: AppOptions(projectId: 'demo-firestore-test'),
      );
    },
    skip: hasEmulator ? null : 'no FIRESTORE_EMULATOR_HOST',
  );
}
```

### Admin auth suite

```dart
@TestOn('vm')
library;

import 'package:tekartik_firebase_admin_sdk/firebase_admin_sdk.dart';
import 'package:tekartik_firebase_admin_sdk/firebase_auth_admin_sdk.dart';
import 'package:tekartik_firebase_auth/auth_admin.dart';
import 'package:tekartik_firebase_auth_test/auth_admin_test_runner.dart';
import 'package:test/test.dart';

/// Run with FIREBASE_AUTH_EMULATOR_HOST=localhost:9099 exported.
void main() {
  late FirebaseApp app;
  setUpAll(() {
    app = firebaseAdminSdk.initializeApp(
      options: AppOptions(projectId: 'demo-auth-test'),
      name: 'auth-test',
    );
  });
  tearDownAll(() async {
    await app.delete();
  });

  // No sign in on the admin sdk, only the admin runner applies.
  firebaseAuthAdminTests(
    getAuth: () => firebaseAuthServiceAdminSdk.auth(app) as FirebaseAuthAdmin,
    email: 'test@example.com',
    password: 'password',
  );
}
```

### Storage suite, skipped by default

```dart
@TestOn('vm')
library;

import 'package:tekartik_firebase_admin_sdk/firebase_admin_sdk.dart';
import 'package:tekartik_firebase_admin_sdk/firebase_storage_admin_sdk.dart';
import 'package:tekartik_firebase_storage_test/storage_test.dart';
import 'package:test/test.dart';

void main() {
  group(
    'storage_admin_sdk',
    () {
      runStorageTests(
        firebase: firebaseAdminSdk,
        storageService: firebaseStorageServiceAdminSdk,
        options: AppOptions(
          projectId: 'demo-storage-test',
          storageBucket: 'demo-storage-test.appspot.com',
        ),
        storageOptions: TestStorageOptions(rootPath: 'tests'),
      );
    },
    // Needs a real bucket or the storage emulator.
    skip: true,
  );
}
```
