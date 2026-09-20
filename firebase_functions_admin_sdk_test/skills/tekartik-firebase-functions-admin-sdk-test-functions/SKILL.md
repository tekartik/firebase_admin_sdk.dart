---
name: tekartik-firebase-functions-admin-sdk-test-functions
description: >-
  Use when writing, registering or extending the admin sdk test Cloud Functions
  of tekartik_firebase_functions_admin_sdk_test: declareRunner,
  basicDeclareRunner, functionsHttpV1Handler, functionsCallV1Handler,
  functionsTaskV1Handler, functionsTaskFirestoreV1Handler,
  functionsPubsubV1Handler, functionsPubsubFirestoreV1Handler,
  callBasicAdminSdkHandler, testDartFunctionHttpsV1, testDartFunctionCallV1,
  testDartFunctionTaskV1, testDartPubsubTopicV1, testApiCommandEcho and the
  other testApiCommand* constants, TestApiRequest,
  testFunctionsApiInitBuilders, testTaskRecordList, testPubsubRecordList,
  firebaseFunctionsFirestore, firebaseFunctionsMenuMain.
---

# The test functions (tekartik_firebase_functions_admin_sdk_test)

`lib/functions.dart` holds the Cloud Functions the shared test suite calls:
one http, one callable that doubles as a remote command api, two task
dispatched and two Pub/Sub functions. They are registered twice — deployed
through `functions/bin/server.dart`, locally through `declareRunner`.

## Guidelines

* Single import for the handlers and the constants:
  `import 'package:tekartik_firebase_functions_admin_sdk_test/functions.dart';`.
  It re-exports `package:tekartik_firebase_functions_test/functions_basic.dart`
  (`TestApiRequest`, `TestApiResult`, `basicCallHandler`,
  `testFunctionsApiInitBuilders`), `src/constants.dart`,
  `src/functions_basic_admin_sdk.dart` and `src/task_record.dart`.
  Call `testFunctionsApiInitBuilders()` once before registering anything: it
  registers the `cv` builders `TestApiRequest` needs.

* Function names and topics are constants, never literals:
  `testDartFunctionHttpsV1` (`admin-sdk-https-v1`), `testDartFunctionCallV1`,
  `testDartFunctionTaskV1`, `testDartFunctionTaskFirestoreV1`,
  `testDartFunctionPubsubV1` on `testDartPubsubTopicV1`,
  `testDartFunctionPubsubFirestoreV1` on `testDartPubsubTopicFirestoreV1`,
  plus the firestore collections `testTasksFirestoreCollectionPath` and
  `testPubsubFirestoreCollectionPath`.

* The callable `functionsCallV1Handler` is a command dispatcher keyed on the
  `command` field of a `TestApiRequest`: `testApiCommandEcho`,
  `testApiCommandAuthUsers`, `testApiCommandAuthMe`,
  `testApiCommandTasksEnqueue` (extra `name`, `region`, `uri`, `data`),
  `testApiCommandTasksList` / `Clear`, `testApiCommandTasksFirestoreList` /
  `Clear`, `testApiCommandPubsubPublish` (extra `topic`, `data`),
  `testApiCommandPubsubList` / `Clear`, `testApiCommandPubsubFirestoreList` /
  `Clear`. Any other payload is echoed with `authUid` and `instanceIdToken`.
  That function is how a test running off the functions machine enqueues a
  task or publishes a message: only the function has admin credentials.

* Two recording strategies, both needed:
  - a temp file (`src/task_record.dart`: `testTaskRecordAdd/List/Clear`,
    `testPubsubRecordAdd/List/Clear`, `testRecordFile(kind)` under
    `Directory.systemTemp`), used by `functionsTaskV1Handler` and
    `functionsPubsubV1Handler`. Readable by the test only when the function
    runs in a process on the same machine.
  - firestore (`functionsTaskFirestoreV1Handler`,
    `functionsPubsubFirestoreV1Handler`), read back through the call function,
    which also works on the emulator and deployed.
  Prefer the firestore variants for any new trigger.

* Inside a handler get firestore with
  `firebaseFunctionsFirestore(firebaseFunctions)`: it is
  `firebaseFunctions.app.getProduct<Firestore>()` and throws `StateError` when
  the product was not registered. Register it in the `runFunctions` builder
  (`firestoreServiceAdminSdk.firestore(firebase.firebaseApp)`) or, locally, on
  the app passed to the http test context.

* `declareRunner(FirebaseFunctionsAdminSdkHttp functions, {String? prefix})`
  registers all six functions on a local
  `tekartik_firebase_functions_admin_sdk_http` server, with `prefix` prepended
  to every name so several suites can share one server.
  `basicDeclareRunner(functions, prefix:)` registers only
  `'<prefix>basic'` -> `callBasicAdminSdkHandler` (commands `echo`,
  `not-found` which throws `HttpResponseException.notFound`, and
  `project-id`), the entry point of the cross-implementation `basicTestGroup`.

* The deployed side is `functions/bin/server.dart`, a separate pub package
  declared in the repo root `workspace:`. There the `name:`, `topic:` and every
  `options:` field must be const literals so `package:firebase_functions`
  generates `functions.yaml`; `firebase.tasks.onTaskDispatched` and
  `firebase.pubsub.onMessagePublished` still need
  `// ignore: experimental_member_use`. Wrap each handler with
  `firebase.httpsHandler` / `firebase.callHandler` / `firebase.taskHandler` /
  `firebase.pubsubHandler`.

* `firebase.json` must declare the emulator ports the functions use
  (`functions: 5001`, `auth: 9099`, `firestore: 8080`, `pubsub: 8085`) and
  `firestore.rules`. Tooling: `tool/firebase_functions_menu.dart` ->
  `firebaseFunctionsMenuMain` (delete / generate / dump `functions.yaml`,
  start / stop the emulator), `tool/delete_generate_dump_functions.dart` ->
  `deleteGenerateAndDumpFunctions()`, `tool/compile_dart_function.dart` ->
  `dart compile exe bin/server.dart --target-os=linux --target-arch=x64`.
  `functions.yaml` is generated, never edit it.

* Adding a function: add its name (and topic) to `src/constants.dart`, write
  the handler in `functions.dart`, register it in `declareRunner` **and** in
  `functions/bin/server.dart`, then add a group in `functions_test_runner.dart`
  so all three contexts exercise it.

## Examples

### `functions/bin/server.dart`: the deployed registration

```dart
import 'package:tekartik_firebase_admin_sdk/firebase_auth_admin_sdk.dart';
import 'package:tekartik_firebase_admin_sdk/firestore_admin_sdk.dart';
import 'package:tekartik_firebase_functions_admin_sdk/functions_admin_sdk.dart';
import 'package:tekartik_firebase_functions_admin_sdk_test/functions.dart';

void main(List<String> args) {
  testFunctionsApiInitBuilders();

  runFunctions((firebase) {
    var app = firebase.firebaseApp;
    firebaseAuthServiceAdminSdk.auth(app);
    firestoreServiceAdminSdk.firestore(app);

    firebase.https.onRequest(
      firebase.httpsHandler(functionsHttpV1Handler),
      name: testDartFunctionHttpsV1,
      options: const HttpsOptions(
        cors: Cors(['*']),
        maxInstances: Instances(11),
        region: Region(SupportedRegion.europeWest1),
        timeoutSeconds: TimeoutSeconds(19),
      ),
    );
    firebase.https.onCall(
      firebase.callHandler(functionsCallV1Handler),
      name: testDartFunctionCallV1,
      options: const CallableOptions(
        cors: Cors(['*']),
        region: Region(SupportedRegion.europeWest1),
      ),
    );
    // ignore: experimental_member_use
    firebase.tasks.onTaskDispatched(
      firebase.taskHandler(functionsTaskFirestoreV1Handler),
      name: testDartFunctionTaskFirestoreV1,
      options: const TaskQueueOptions(
        region: Region(SupportedRegion.europeWest1),
        retryConfig: TaskQueueRetryConfig(maxAttempts: MaxAttempts(2)),
      ),
    );
    // ignore: experimental_member_use
    firebase.pubsub.onMessagePublished(
      firebase.pubsubHandler(functionsPubsubFirestoreV1Handler),
      topic: testDartPubsubTopicFirestoreV1,
      options: const PubSubOptions(region: Region(SupportedRegion.europeWest1)),
    );
  });
}
```

### Local registration on the http server

```dart
import 'package:tekartik_firebase_functions_admin_sdk_http/functions_admin_sdk_http.dart';
import 'package:tekartik_firebase_functions_admin_sdk_test/functions.dart';

/// Same handlers as the deployed server, on a local http server.
void declareMyRunner(FirebaseFunctionsAdminSdkHttp functions, {String? prefix}) {
  prefix ??= '';
  testFunctionsApiInitBuilders();

  functions.https.onAdminSdkRequest(
    '$prefix$testDartFunctionHttpsV1',
    functionsHttpV1Handler,
  );
  functions.https.onAdminSdkCall(
    '$prefix$testDartFunctionCallV1',
    functionsCallV1Handler,
  );
  functions.tasks.onAdminSdkTaskDispatched(
    '$prefix$testDartFunctionTaskV1',
    functionsTaskV1Handler,
  );
  functions.pubsub.onAdminSdkMessagePublished(
    '$prefix$testDartFunctionPubsubV1',
    topic: testDartPubsubTopicV1,
    handler: functionsPubsubV1Handler,
  );
  // The `basic` callable used by the cross implementation suite.
  basicDeclareRunner(functions, prefix: prefix);
}
```

### A new handler recording in firestore

```dart
import 'package:tekartik_firebase_functions_admin_sdk/functions_admin_sdk.dart';
import 'package:tekartik_firebase_functions_admin_sdk_test/functions.dart';

/// Records what it receives so a test can read it back through the call
/// function, even when the function does not run on the test machine.
Future<void> myTaskFirestoreHandler(
  FirebaseFunctions firebaseFunctions,
  TaskRequest<Object?> request,
) async {
  // Throws a StateError if firestore was not registered on the app.
  var firestore = firebaseFunctionsFirestore(firebaseFunctions);
  await firestore
      .collection(testTasksFirestoreCollectionPath)
      .doc(request.id)
      .set(taskRequestToMap(request));
}

/// The temp file variant, only readable when the function runs locally.
Future<void> myPubsubHandler(
  FirebaseFunctions firebaseFunctions,
  CloudEvent<PubsubMessage> event,
) async {
  await testPubsubRecordAdd(pubsubEventToMap(event));
}
```

### Driving the test call function from a test

```dart
import 'dart:convert';

import 'package:tekartik_firebase_functions_admin_sdk_test/functions.dart';
import 'package:tekartik_firebase_functions_admin_sdk_test/test_context.dart';
import 'package:tekartik_http/http.dart';

/// Sends a `TestApiRequest` command to the callable test function and returns
/// its `result`.
Future<Map<String, Object?>> callCommand(
  FirebaseFunctionsAdminSdkTestContext context,
  String command,
) async {
  testFunctionsApiInitBuilders();
  var request = TestApiRequest()..command.v = command;
  var response = await httpClientSend(
    context.client,
    httpMethodPost,
    context.httpsUri(testDartFunctionCallV1),
    headers: (HttpHeaders()..mimeType = httpContentTypeJson).toStringMap(),
    body: jsonEncode({'data': request.toMap()}),
  );
  if (response.statusCode != httpStatusCodeOk) {
    throw StateError('$command failed ${response.statusCode}');
  }
  return ((jsonDecode(response.body) as Map)['result'] as Map)
      .cast<String, Object?>();
}

/// `callCommand(context, testApiCommandPubsubFirestoreList)` returns
/// `{'messages': [...]}`, `testApiCommandEcho` echoes the request back.
```
