# tekartik_firebase_admin_sdk

Server side Firebase with admin credentials, behind the platform neutral
tekartik abstractions (`tekartik_firebase`, `tekartik_firebase_firestore`,
`tekartik_firebase_auth`, `tekartik_firebase_storage`), on top of the Dart
[firebase_admin_sdk](https://pub.dev/packages/firebase_admin_sdk). Also
publishes Pub/Sub messages and enqueues Cloud Tasks.

Dart VM only: Cloud Run, Cloud Functions in Dart, scripts, tests.

## Getting started

Git package, not on pub.dev:

```yaml
dependencies:
  tekartik_firebase_admin_sdk:
    git:
      url: https://github.com/tekartik/firebase_admin_sdk.dart
      path: firebase_admin_sdk
```

Initialize one app per process, then get the products from the services:

```dart
import 'package:tekartik_firebase_admin_sdk/firebase_admin_sdk.dart';
import 'package:tekartik_firebase_admin_sdk/firestore_admin_sdk.dart';

Future<void> main() async {
  // Credentials and project from the environment (Cloud Run, Cloud
  // Functions, GOOGLE_APPLICATION_CREDENTIALS, or the emulators).
  var app = firebaseAdminSdk.initializeApp(
    options: AppOptions(projectId: 'my-project'),
  );
  var firestore = firestoreServiceAdminSdk.firestore(app);

  await firestore.doc('users/alice').set({'name': 'Alice'});
  var snapshot = await firestore.doc('users/alice').get();
  print(snapshot.data);

  await app.delete();
}
```

Credentials:

* No `options`, or options without credentials: the native sdk uses the
  application default credentials and reads `GOOGLE_CLOUD_PROJECT`,
  `GCLOUD_PROJECT` or `FIREBASE_CONFIG` (the Cloud Run / Cloud Functions
  case, or `GOOGLE_APPLICATION_CREDENTIALS` on a machine).
* A service account json: `await firebaseAdminSdk.initializeAppWithServiceAccountMap(map)`
  (`project_id`, `client_email`, `private_key`; only `storageBucket` of its
  `options` is kept). Never commit that file.
* Emulators: export `FIRESTORE_EMULATOR_HOST`, `FIREBASE_AUTH_EMULATOR_HOST`,
  `FIREBASE_STORAGE_EMULATOR_HOST`, `CLOUD_TASKS_EMULATOR_HOST`,
  `PUBSUB_EMULATOR_HOST`; a `demo-xxx` project id needs no credentials.

## Products

| Import (`package:tekartik_firebase_admin_sdk/...`) | Service | Gives |
|---|---|---|
| `firebase_admin_sdk.dart` | `firebaseAdminSdk` | `FirebaseApp` (`initializeApp`, `app()`) |
| `firestore_admin_sdk.dart` | `firestoreServiceAdminSdk.firestore(app)` | `Firestore` |
| `firebase_auth_admin_sdk.dart` | `firebaseAuthServiceAdminSdk.auth(app)` | `FirebaseAuth`, also a `FirebaseAuthAdmin` (`createUser`, `deleteUser`, `verifyIdToken`, `listUsers`) |
| `firebase_storage_admin_sdk.dart` | `firebaseStorageServiceAdminSdk.storage(app)` | `FirebaseStorage` (needs a `storageBucket` or a bucket name) |
| `firebase_pubsub_admin_sdk.dart` | `firebasePubsubServiceAdminSdk.topic(app, name)` | publish to a Pub/Sub topic |
| `firebase_tasks_admin_sdk.dart` | `firebaseTasksServiceAdminSdk.taskQueue(app, function)` | enqueue a Cloud Task |

Each library re-exports its abstraction. Keep business code on the
abstractions (`Firestore`, `FirebaseAuth`...) so that it also runs on the
memory backends in tests (`tekartik_firebase_local`, `tekartik_firebase_firestore_sembast`).
A product is created once per app: after the first call, `app.firestore()`,
`app.auth()` and `app.storage()` return the same instance.

## Common pitfalls

* No listeners: `onSnapshot`, `onCount` and `documentChanges` throw
  `UnsupportedError` (`supportsTrackChanges` is false). `aggregate` throws,
  `query.count()` works.
* Only `projectId` and `storageBucket` of the options reach the native sdk.
* Initialize a name once and keep the `FirebaseApp`: a second
  `initializeApp` of the same name gives another `FirebaseApp` without the
  products of the first one.
* Auth is server side: no current user (`onCurrentUser` emits `null` once),
  no sign in. `getUser` and `getUserByEmail` return `null` for a missing user
  and throw the other errors.
* Storage: `getFiles` reads every page of the listing in one call
  (`maxResults` is the page size, `nextQuery` is always null), keep a
  `prefix`. `getDownloadUrl()` is not supported.
* On the web, `firebase_admin_sdk.dart`, `firebase_auth_admin_sdk.dart` and
  `firebase_storage_admin_sdk.dart` compile and their services throw
  `UnsupportedError`; `firestore_admin_sdk.dart` does not compile there
  (the native sdk uses `dart:ffi`). Keep the admin sdk imports in VM only
  files.
* Call `app.delete()` when done (tests: `tearDownAll`).

The [tekartik-firebase-admin-sdk-setup skill](skills/tekartik-firebase-admin-sdk-setup/SKILL.md)
has more examples (users, Pub/Sub, Cloud Tasks, a Cloud Functions server).
