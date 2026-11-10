# tekartik_firebase_admin_sdk_test

The tests of `tekartik_firebase_admin_sdk` (same repository): the shared
tekartik Firebase suites (`tekartik_firebase_test`, `tekartik_firebase_auth_test`,
`tekartik_firebase_firestore_test`, `tekartik_firebase_storage_test`) run
against the admin sdk, on the Firebase emulators. A test-only package: no
`lib/`, nothing to depend on.

## Running the tests

From this folder (the repository is a pub workspace, `dart pub get` at its
root):

```sh
dart test
```

Offline, it runs the app tests (`runFirebaseTests`), the firestore and pub/sub
offline checks and a raw test of the native `firebase_admin_sdk` apps. The
emulator tests need the Firebase CLI (`firebase`, Node.js) and an
`emulator/.firebaserc` (git ignored, any project id:
`{"projects": {"default": "<project id>"}}`); they are skipped without it:

* `firebase_auth_admin_sdk_emulator_test.dart`: auth emulator, id token
  verification, user metadata.
* `firebase_storage_admin_sdk_emulator_test.dart`: storage emulator, the
  shared storage suite and the cache control headers.
* `firebase_admin_sdk_emulator_suites_test.dart`: auth and firestore
  emulators (Java for firestore), the shared auth suites (`runAuthAppTests`,
  `firebaseAuthAdminTests`) and the whole shared firestore suite, on a `demo-`
  project. It needs the emulator hosts in the process environment, it is
  skipped otherwise:

  ```sh
  FIREBASE_AUTH_EMULATOR_HOST=127.0.0.1:9099 \
  FIRESTORE_EMULATOR_HOST=127.0.0.1:8080 \
    dart test test/firebase_admin_sdk_emulator_suites_test.dart
  ```

Each emulator test starts its emulators (`tekartik_firebase_emulator`, ports
in `emulator/firebase.json`) and stops them; a machine wide lock makes them
run one after the other.

## What to know

* Known failure: the storage suite `list_files_pages` fails on the admin sdk
  (its `getFiles` gives every file in one page and no next query: the native
  `listObjects` stream takes no page token).
* The admin sdk reads the emulator hosts from the zone environment of the
  native sdk first (its own tests use it), then from the process
  environment. A zone around the test declarations does not reach the test
  bodies under `dart test` (it does when the file is run with `dart <file>`),
  and the firestore client (`google_cloud_firestore`) reads its own zone key:
  without the process environment, firestore calls go to the real project of
  the application default credentials. Hence the `demo-` project and the
  environment check of the suites test.
* No current user on the admin sdk (`supportsCurrentUser` is false): the sign
  in checks of the shared auth suites are skipped. The firestore emulator
  locks a document read in a transaction, so `skipConcurrentTransactionTests`
  is set there (the write outside of the transaction would wait).

See `skills/tekartik-firebase-admin-sdk-test-setup` to run the same suites
in your own project (`dart run skills@ get`).
