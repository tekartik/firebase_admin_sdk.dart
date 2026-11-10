---
name: tekartik-firebase-admin-sdk-test-setup
description: >-
  Use when running or adding the shared tekartik firebase test suites against
  the admin sdk implementation (tekartik_firebase_admin_sdk):
  tekartik_firebase_admin_sdk_test, runFirebaseTests, runFirestoreTests,
  runAuthTests, runStorageTests, firebaseAuthAdminTests, TestStorageOptions,
  firebaseAdminSdk, firestoreServiceAdminSdk, firebaseAuthServiceAdminSdk,
  firebaseStorageServiceAdminSdk, skipConcurrentTransactionTests, the
  emulator variables FIRESTORE_EMULATOR_HOST / FIREBASE_AUTH_EMULATOR_HOST /
  FIREBASE_STORAGE_EMULATOR_HOST / PUBSUB_EMULATOR_HOST, and why an admin sdk
  test meant for an emulator can reach the real project.
---

# Shared test suites for the admin sdk (tekartik_firebase_admin_sdk_test)

A test-only package: it has **no `lib/`**, only `test/`. It exists to run the
cross-implementation suites of `tekartik_firebase_test`,
`tekartik_firebase_firestore_test`, `tekartik_firebase_auth_test` and
`tekartik_firebase_storage_test` against `tekartik_firebase_admin_sdk` on the
Firebase emulators, plus a raw test of the native `firebase_admin_sdk` app
lifecycle. Its README lists the test files and how to run them.

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
  - `runAuthTests(firebase:, authService:, options:, name:)` (or
    `runAuthAppTests(authService:, app:)` on your app) and, from
    `auth_admin_test_runner.dart`,
    `firebaseAuthAdminTests(getAuth:, email:, password:)` which takes a
    `FirebaseAuthAdmin` (cast `firebaseAuthServiceAdminSdk.auth(app)`); the
    user of `email` is created and deleted.
  - `runStorageTests(firebase:, storageService:, options:, storageOptions:)`
    (or `runStorageAppTests(app, ...)`) with
    `TestStorageOptions(bucket:, rootPath:, skipDefaultBucketExists:)`.

  `runFirebaseTests` creates its app in `setUpAll`; `runFirestoreTests`,
  `runAuthTests` and `runStorageTests` create theirs when they are declared
  (no request is sent) and delete it in `tearDownAll`. The `...AppTests`
  variants take your app and leave it to you.

* Every suite but `runFirebaseTests` talks to a backend. Point them at the
  emulators with the **process environment** before `dart test`:
  `FIRESTORE_EMULATOR_HOST=127.0.0.1:8080`,
  `FIREBASE_AUTH_EMULATOR_HOST=127.0.0.1:9099`,
  `FIREBASE_STORAGE_EMULATOR_HOST=127.0.0.1:9199`,
  `CLOUD_TASKS_EMULATOR_HOST`, `PUBSUB_EMULATOR_HOST=127.0.0.1:8085`, with
  `AppOptions(projectId: 'demo-xxx')`: no credentials needed, and a `demo-`
  project can never be a real one. Skip the test when the variable is missing
  (`Platform.environment` check, see the examples) so `dart test` stays green
  offline and never reaches a real backend. Against a real project export
  `GOOGLE_APPLICATION_CREDENTIALS` instead, and use a throw-away project: the
  suites write and delete documents, users and files.

* The native sdk also reads a zone environment (`envSymbol` of
  `package:firebase_admin_sdk/src/app.dart`, internal, used by its tests and
  by this package's auth and storage emulator tests), but: a zone around the
  test declarations does not reach the test bodies under `dart test` (it does
  when the file is run with `dart <file>`, so a probe can behave differently),
  and `google_cloud_firestore` reads its own zone key, not that one. A
  firestore call made without the process variable goes to the real project
  of the application default credentials (`gcloud auth
  application-default login` on the machine). Wrap each call in the zone
  (`runZoned` inside the test body, as `_inEmulator` does) or, for a shared
  suite, use the process environment. The storage emulator host is read
  when the storage is created (`firebaseStorageServiceAdminSdk.storage(app)`,
  then the first `bucket()`), so a zone around that creation is enough.

* Expect capability skips, not bugs, when a suite is too broad for the admin
  sdk: `FirestoreService.supportsTrackChanges` and `supportsAggregateQueries`
  are `false` (`onSnapshot`, `documentChanges` and `aggregate` throw, the
  suite skips them), and `FirebaseAuthService.supportsCurrentUser` is `false`
  (no sign in: `firebaseAuthAdminTests` skips its sign in checks, do not use
  the sign in runner). Check the `supportsXxx` flags in a test rather than
  skipping blindly.

* Skip a suite by not declaring it (return early from `main`), not with a
  skipped `group`: package:test lets a test declared with `skip: false`
  inside a skipped group run, and the firestore suite declares about 30
  tests with `skip: <capability check>`. Inside `group(..., skip: true)`
  they still run and reach the backend.

* On the firestore emulator set `skipConcurrentTransactionTests = true`
  (from `firestore_test_runner.dart`): the emulator locks a document read in
  a transaction, the `concurrent_get_update` write outside of it waits for the
  lock and the test times out.

* `createUser` of an existing email or uid throws a `StateError`
  (`email-already-exists: ...`), as the other admin backends.

* Known failure: the storage suite `list_files_pages` fails on the admin sdk
  (`getFiles` gives every file in one page and no `nextQuery`).

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

/// Run with FIRESTORE_EMULATOR_HOST=127.0.0.1:8080 exported, the emulator
/// started (`firebase emulators:start --only firestore --project
/// demo-firestore-test`).
void main() {
  if (Platform.environment['FIRESTORE_EMULATOR_HOST'] == null) {
    // Do not declare the suite at all: a skipped group does not skip its
    // tests declared with `skip: false` (the capability checks).
    test('firestore emulator', () {}, skip: 'no FIRESTORE_EMULATOR_HOST');
    return;
  }
  // The emulator locks a document read in a transaction.
  skipConcurrentTransactionTests = true;
  group('firestore_admin_sdk', () {
    test('supports', () {
      expect(firestoreServiceAdminSdk.supportsTrackChanges, isFalse);
      expect(firestoreServiceAdminSdk.supportsAggregateQueries, isFalse);
    });
    runFirestoreTests(
      firebase: firebaseAdminSdk,
      firestoreService: firestoreServiceAdminSdk,
      options: AppOptions(projectId: 'demo-firestore-test'),
    );
  });
}
```

### Admin auth suite

```dart
@TestOn('vm')
library;

import 'dart:io';

import 'package:tekartik_firebase_admin_sdk/firebase_admin_sdk.dart';
import 'package:tekartik_firebase_admin_sdk/firebase_auth_admin_sdk.dart';
import 'package:tekartik_firebase_auth/auth_admin.dart';
import 'package:tekartik_firebase_auth_test/auth_admin_test_runner.dart';
import 'package:tekartik_firebase_auth_test/auth_test.dart'
    show runAuthAppTests;
import 'package:test/test.dart';

/// Run with FIREBASE_AUTH_EMULATOR_HOST=127.0.0.1:9099 exported, the emulator
/// started (`firebase emulators:start --only auth --project demo-auth-test`).
void main() {
  if (Platform.environment['FIREBASE_AUTH_EMULATOR_HOST'] == null) {
    test('auth emulator', () {}, skip: 'no FIREBASE_AUTH_EMULATOR_HOST');
    return;
  }
  // Created when declared (no request sent), runAuthAppTests needs it.
  var app = firebaseAdminSdk.initializeApp(
    options: AppOptions(projectId: 'demo-auth-test'),
    name: 'auth-test',
  );
  tearDownAll(() async {
    await app.delete();
  });

  runAuthAppTests(authService: firebaseAuthServiceAdminSdk, app: app);
  // No current user on the admin sdk: the sign in checks are skipped.
  firebaseAuthAdminTests(
    getAuth: () => firebaseAuthServiceAdminSdk.auth(app) as FirebaseAuthAdmin,
    email: 'test@example.com',
    password: 'password',
  );
}
```

### Storage suite against the emulator

```dart
@TestOn('vm')
library;

import 'dart:io';

import 'package:tekartik_firebase_admin_sdk/firebase_admin_sdk.dart';
import 'package:tekartik_firebase_admin_sdk/firebase_storage_admin_sdk.dart';
import 'package:tekartik_firebase_storage_test/storage_test.dart';
import 'package:test/test.dart';

/// Run with FIREBASE_STORAGE_EMULATOR_HOST=127.0.0.1:9199 exported, the
/// emulator started (`firebase emulators:start --only storage --project
/// demo-storage-test`, with rules allowing the writes, as
/// `emulator/storage.rules` of this package).
void main() {
  if (Platform.environment['FIREBASE_STORAGE_EMULATOR_HOST'] == null) {
    test('storage emulator', () {}, skip: 'no FIREBASE_STORAGE_EMULATOR_HOST');
    return;
  }
  group('storage_admin_sdk', () {
    runStorageTests(
      firebase: firebaseAdminSdk,
      storageService: firebaseStorageServiceAdminSdk,
      options: AppOptions(
        projectId: 'demo-storage-test',
        storageBucket: 'demo-storage-test.appspot.com',
      ),
      storageOptions: TestStorageOptions(
        bucket: 'demo-storage-test.appspot.com',
        rootPath: 'tests',
        // As this package's emulator test.
        skipDefaultBucketExists: true,
      ),
    );
  });
}
```
