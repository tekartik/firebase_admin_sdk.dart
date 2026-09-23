---
name: tekartik-firebase-admin-sdk-setup
description: >-
  Use when writing server side Dart (Cloud Run, Cloud Functions, scripts,
  tests) that reaches Firebase with admin credentials through the tekartik
  abstractions: initializing firebaseAdminSdk apps (service account, env,
  emulators), getting the Firestore, Auth and Storage services, publishing
  Pub/Sub messages and enqueuing Cloud Tasks with tekartik_firebase_admin_sdk.
---

# tekartik_firebase_admin_sdk setup

Implements `tekartik_firebase`, `tekartik_firebase_firestore`,
`tekartik_firebase_auth` and `tekartik_firebase_storage` on top of the Dart
`firebase_admin_sdk` package. Dart VM only: on the web every getter throws.

## Guidelines

* Import one library per product from `package:tekartik_firebase_admin_sdk/`,
  each re-exports its abstraction: `firebase_admin_sdk.dart` (`FirebaseApp`,
  `AppOptions`, `firebaseAdminSdk`), `firestore_admin_sdk.dart`
  (`firestoreServiceAdminSdk`), `firebase_auth_admin_sdk.dart`
  (`firebaseAuthServiceAdminSdk`), `firebase_storage_admin_sdk.dart`
  (`firebaseStorageServiceAdminSdk`), `firebase_tasks_admin_sdk.dart` and
  `firebase_pubsub_admin_sdk.dart`. Do not import `package:firebase_admin_sdk`
  in application code: keep business code on the abstractions.
* `firebaseAdminSdk` is the `FirebaseAdminSdk` entry point (`Firebase` and
  `FirebaseAdmin`). `initializeApp(options:, name:)` is synchronous
  (`initializeAppAsync` exists too). Only `projectId` and `storageBucket` of
  `AppOptions` reach the native SDK; the other fields are ignored.
* Credentials: with no `options` the native SDK reads `FIREBASE_CONFIG`,
  `GOOGLE_APPLICATION_CREDENTIALS` (application default credentials, the
  Cloud Run / Cloud Functions case) and `GOOGLE_CLOUD_PROJECT`/`GCLOUD_PROJECT`.
  For an explicit service account json call
  `initializeAppWithServiceAccountMap(map, options:)` (async): it reads
  `project_id`, `client_email`, `private_key`, `client_id` from the map and
  only honors `storageBucket` from `options`. Never commit that json.
* Emulators: export `FIRESTORE_EMULATOR_HOST`, `FIREBASE_AUTH_EMULATOR_HOST`,
  `FIREBASE_STORAGE_EMULATOR_HOST`, `CLOUD_TASKS_EMULATOR_HOST` (native SDK)
  and `PUBSUB_EMULATOR_HOST` (this package, see `pubsubEmulatorHost`). Then
  `AppOptions(projectId: 'demo-x')` is enough, no credentials are needed.
* Initialize an app once per process and keep the `FirebaseApp`; call
  `app.delete()` in `tearDownAll`. `app.hasAdminCredentials` is `true`. The
  native SDK throws when the same name is initialized with other options.
* Services are singletons cached per app: `firestoreServiceAdminSdk.firestore(app)`,
  `firebaseAuthServiceAdminSdk.auth(app)`, `firebaseStorageServiceAdminSdk.storage(app)`.
  After the first call `app.firestore()`, `app.auth()`, `app.storage()` (the
  `FirebaseApp` extensions) and `app.getProduct<Firestore>()` return the same
  instance. In a functions server create them once in the `runFunctions`
  builder, then use `firebaseFunctions.app` inside the handlers.
* Firestore: check the `FirestoreService.supportsXxx` flags first.
  `supportsTrackChanges` is `false`: `onSnapshot` and `documentChanges` throw
  `UnsupportedError`. `supportsAggregateQueries` is `false` (`aggregate`
  throws) but `Query.count()` works. `listCollections`, `select`, `Timestamp`,
  `Blob`, `GeoPoint`, `VectorValue` and `FieldValue` are supported.
  `collRef.listDocuments()` also lists the missing documents that only hold
  sub collections (`supportsListMissingDocuments`); the native call only
  returns the first page of the backend (about 300 documents) and paging
  options are applied locally.
* Auth is server side only: `supportsCurrentUser` is `false` (no sign in),
  `supportsListUsers` is `true`. `listUsers`, `getUser` and `getUserByEmail`
  are on `FirebaseAuth` and return `null` when the user is missing (or on any
  error). `createUser`, `deleteUser` and the `getOrCreateUser` helper are on
  `FirebaseAuthAdmin` from `package:tekartik_firebase_auth/auth_admin.dart`:
  cast the auth. `createUser` only forwards `uid`, `email`, `password` and
  `disabled` (`displayName`, `phoneNumber`, `emailVerified` are ignored).
* Storage: `storage.bucket()` needs `storageBucket` in the app options or an
  explicit name, otherwise `StateError`. `Reference.getDownloadUrl()` throws
  `UnsupportedError`. `File.metadata` is always `null`: `await getMetadata()`.
* Cloud Tasks: `firebaseTasksServiceAdminSdk.taskQueue(app, functionName,
  region:)` targets a task dispatched function (`tasks.onTaskDispatched` in
  `tekartik_firebase_functions_admin_sdk`); `null` region means `us-central1`.
  `enqueue(data, options: FirebaseTaskEnqueueOptions(...))` takes `id` for
  de-duplication, `scheduleDelay` or `scheduleTime` (both set throws
  `ArgumentError`), `dispatchDeadlineSeconds`, `headers` and `uri`, required
  with the Cloud Tasks emulator. `delete(id)` removes a pending task.
* Pub/Sub: `firebasePubsubServiceAdminSdk.topic(app, name)`; call
  `createIfNeeded()` once (409 is ignored), then `publish(map)`,
  `publishText(text)` or `publishBytes(bytes)`, each returning the message id.
  `FirebasePubsubPublishOptions(attributes:, orderingKey:)` sets the metadata.
  The app must have a `projectId` (`StateError` otherwise). The consumer is
  `pubsub.onMessagePublished` of `tekartik_firebase_functions_admin_sdk`.
* `firebaseAdminSdk.fromNativeApp(rawApp)` (import `mixin_admin_sdk.dart`)
  wraps a native app you did not create; `firebase.firebaseApp` in
  `tekartik_firebase_functions_admin_sdk` does exactly that. Same interfaces,
  other backends: `tekartik_firebase_rest` (REST, user or service account
  token), `tekartik_firebase_node` (Node.js), local/sembast ones for tests.

## Examples

### Service account app, Firestore and Storage

```dart
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:tekartik_firebase_admin_sdk/firebase_admin_sdk.dart';
import 'package:tekartik_firebase_admin_sdk/firebase_storage_admin_sdk.dart';
import 'package:tekartik_firebase_admin_sdk/firestore_admin_sdk.dart';

Future<void> main() async {
  var serviceAccountMap =
      jsonDecode(Platform.environment['SERVICE_ACCOUNT_JSON']!) as Map;
  var app = await firebaseAdminSdk.initializeAppWithServiceAccountMap(
    serviceAccountMap,
    options: AppOptions(storageBucket: 'my-project.appspot.com'),
  );
  var firestore = firestoreServiceAdminSdk.firestore(app);
  var storage = firebaseStorageServiceAdminSdk.storage(app);

  await firestore.doc('users/alice').set({'name': 'Alice'});
  var file = storage.bucket().file('exports/users.json');
  await file.upload(
    Uint8List.fromList(utf8.encode('{}')),
    options: StorageUploadFileOptions(contentType: 'application/json'),
  );
  await app.delete();
}
```

### Managing users

```dart
import 'package:tekartik_firebase_admin_sdk/firebase_admin_sdk.dart';
import 'package:tekartik_firebase_admin_sdk/firebase_auth_admin_sdk.dart';
import 'package:tekartik_firebase_auth/auth_admin.dart';

Future<void> ensureAdminUser(FirebaseApp app) async {
  var auth = firebaseAuthServiceAdminSdk.auth(app) as FirebaseAuthAdmin;
  var record = await auth.getOrCreateUser(
    FirebaseAuthCreateUserRequest(email: 'admin@example.com', password: 'p'),
  );
  print('admin uid ${record.uid}');

  var result = await auth.listUsers(maxResults: 100);
  print(result.users.map((user) => user?.email).toList());
}
```

### Enqueuing a task and publishing a message (emulators)

```dart
import 'package:tekartik_firebase_admin_sdk/firebase_admin_sdk.dart';
import 'package:tekartik_firebase_admin_sdk/firebase_pubsub_admin_sdk.dart';
import 'package:tekartik_firebase_admin_sdk/firebase_tasks_admin_sdk.dart';

/// Run with CLOUD_TASKS_EMULATOR_HOST and PUBSUB_EMULATOR_HOST exported.
Future<void> main() async {
  var app = firebaseAdminSdk.initializeApp(
    options: AppOptions(projectId: 'demo-project'),
  );

  var queue = firebaseTasksServiceAdminSdk
      .taskQueue(app, 'sendReport', region: 'europe-west1');
  await queue.enqueue(
    {'reportId': 'r1'},
    options: FirebaseTaskEnqueueOptions(
      id: 'report-r1',
      scheduleDelay: const Duration(minutes: 5),
      uri: 'http://localhost:5001/demo-project/europe-west1/sendReport',
    ),
  );

  var topic = firebasePubsubServiceAdminSdk.topic(app, 'events');
  await topic.createIfNeeded();
  var messageId = await topic.publish(
    {'type': 'user_created', 'uid': 'u1'},
    options: const FirebasePubsubPublishOptions(attributes: {'v': '1'}),
  );
  print('published $messageId (emulator: ${pubsubEmulatorHost != null})');
  await app.delete();
}
```

### Inside a Cloud Functions server

```dart
import 'package:tekartik_firebase_admin_sdk/firebase_auth_admin_sdk.dart';
import 'package:tekartik_firebase_admin_sdk/firestore_admin_sdk.dart';
import 'package:tekartik_firebase_functions_admin_sdk/functions_admin_sdk.dart';

void main() {
  runFunctions((firebase) {
    var app = firebase.firebaseApp;
    firestoreServiceAdminSdk.firestore(app);
    firebaseAuthServiceAdminSdk.auth(app);

    firebase.https.onCall(
      firebase.callHandler((firebaseFunctions, request, response) async {
        var uid = request.auth?.uid;
        var firestore = firebaseFunctions.app.firestore();
        var doc = await firestore.doc('users/$uid').get();
        return CallableResult(doc.exists ? doc.data : <String, Object?>{});
      }),
      name: 'me',
    );
  });
}
```
