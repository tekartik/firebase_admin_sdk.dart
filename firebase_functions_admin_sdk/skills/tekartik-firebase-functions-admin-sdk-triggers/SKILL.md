---
name: tekartik-firebase-functions-admin-sdk-triggers
description: >-
  Use when writing Dart Cloud Functions triggered by Cloud Tasks or Pub/Sub
  with tekartik_firebase_functions_admin_sdk: tasks.onTaskDispatched,
  firebase.taskHandler, FirebaseFunctionsAdminSdkTaskHandler, TaskRequest,
  TaskQueueOptions, TaskQueueRetryConfig, the X-CloudTasks-* headers,
  pubsub.onMessagePublished, firebase.pubsubHandler,
  FirebaseFunctionsAdminSdkPubsubHandler, CloudEvent, PubsubMessage,
  PubSubOptions, pubsubMessagePublishedCloudEventJson and the emulator
  (CLOUD_TASKS_EMULATOR_HOST, PUBSUB_EMULATOR_HOST).
---

# Task queue and Pub/Sub triggers (tekartik_firebase_functions_admin_sdk)

Beyond http and callable functions, this package registers the two background
triggers of the Dart Cloud Functions runtime: `onTaskDispatched` (Cloud Tasks)
and `onMessagePublished` (Pub/Sub), with tekartik handlers that receive a
`FirebaseFunctions` so the same code runs locally and deployed.

## Guidelines

* One import:
  `import 'package:tekartik_firebase_functions_admin_sdk/functions_admin_sdk.dart';`.
  It re-exports the native `TaskRequest`, `CloudEvent`, `PubsubMessage`,
  `TaskQueueOptions`, `PubSubOptions`, `Region`, `SupportedRegion`, and the
  aliases `FirebaseFunctionsAdminSdkTaskRequest<T>`,
  `FirebaseFunctionsAdminSdkCloudEvent<T>`,
  `FirebaseFunctionsAdminSdkPubsubMessage`,
  `FirebaseFunctionsAdminSdkPubsubOptions`,
  `FirebaseFunctionsAdminSdkTaskQueueOptions`.

* Handler signatures:
  `FirebaseFunctionsAdminSdkTaskHandler` is
  `Future<void> Function(FirebaseFunctions, TaskRequest<Object?>)` and
  `FirebaseFunctionsAdminSdkPubsubHandler` is
  `Future<void> Function(FirebaseFunctions, CloudEvent<PubsubMessage>)`.
  Both return `void`: the task/message is acknowledged unless the handler
  throws, which triggers a retry.

* Register in `functions/bin/server.dart` inside `runFunctions`, wrapping the
  handler with `firebase.taskHandler(...)` / `firebase.pubsubHandler(...)`
  (`FirebaseFunctionsAdminSdkFirebaseExt`). Both native namespaces are still
  experimental, so a `// ignore: experimental_member_use` line is needed. The
  name and the options must be `const` for the `package:firebase_functions`
  builder to emit them in `functions.yaml`.

* Naming differs between the two triggers. For a task queue function the
  deployed function name **is** the Cloud Tasks queue name, chosen with
  `name:`. For a Pub/Sub function the deployed name is derived from the topic
  (`onmessagepublished-<topic without hyphens>`) and cannot be chosen; only
  `topic:` matters.

* `TaskRequest` exposes `data`, `id`, `queueName`, `retryCount`,
  `executionCount` and `auth?.uid`. A task dispatched function answers
  `taskDispatchedNoContentStatusCode` (204). The raw Cloud Tasks headers are
  available as constants: `cloudTasksHeaderQueueName`,
  `cloudTasksHeaderTaskName`, `cloudTasksHeaderTaskRetryCount`,
  `cloudTasksHeaderTaskExecutionCount`, `cloudTasksHeaderTaskEta`,
  `cloudTasksHeaderTaskPreviousResponse`, `cloudTasksHeaderTaskRetryReason`.

* `CloudEvent<PubsubMessage>` exposes `source`, `type` (compare with
  `pubsubMessagePublishedEventType`) and `data` (nullable): the
  `PubsubMessage` has `jsonData`, `data`, `attributes`, `messageId`,
  `publishTime` and `orderingKey`.

* The producing side is `tekartik_firebase_admin_sdk`, not this package:
  `firebaseTasksServiceAdminSdk.taskQueue(app, name, region:).enqueue(data)`
  and `firebasePubsubServiceAdminSdk.topic(app, name).publish(map)`. Inside a
  function, use `firebaseFunctions.app` as the app.

* Emulator caveats. The tasks emulator runs with the functions emulator and
  sets `CLOUD_TASKS_EMULATOR_HOST`, but the url the admin sdk builds is the
  production function url, so pass
  `FirebaseTaskEnqueueOptions(uri: 'http://localhost:5001/$projectId/$region/$name')`
  when enqueuing against the emulator. For Pub/Sub, add
  `"pubsub": {"port": 8085}` to `firebase.json` and start it with the
  functions emulator; `PUBSUB_EMULATOR_HOST` is then set for the emulated
  functions.

* To simulate a delivery without Pub/Sub (unit tests, or the local http
  server of `tekartik_firebase_functions_admin_sdk_http`), build the body with
  `pubsubMessagePublishedCloudEventJson(projectId:, topic:, data:, attributes:,
  orderingKey:, messageId:, eventId:, publishTime:)` and POST it. `data` is
  the **base64 encoded** message payload.

* Anti-pattern: do not compute the topic, the name or the options
  (`const PubSubOptions(region: Region(SupportedRegion.europeWest1))` must be
  written inline). Do not rely on the `name` passed to
  `PubsubFunctionsAdminSdk.onMessagePublished` / `functions['x'] = ...` for the
  deployed name: it only keys the local registry.

## Examples

### `functions/bin/server.dart`: a task and a Pub/Sub function

```dart
import 'package:tekartik_firebase_admin_sdk/firestore_admin_sdk.dart';
import 'package:tekartik_firebase_functions_admin_sdk/functions_admin_sdk.dart';

Future<void> sendReportTaskHandler(
  FirebaseFunctions firebaseFunctions,
  TaskRequest<Object?> request,
) async {
  print(
    'task ${request.id} on ${request.queueName} '
    'retry ${request.retryCount} data ${request.data}',
  );
}

Future<void> eventsPubsubHandler(
  FirebaseFunctions firebaseFunctions,
  CloudEvent<PubsubMessage> event,
) async {
  var message = event.data!;
  print('${message.messageId}: ${message.jsonData} ${message.attributes}');
}

void main(List<String> args) {
  runFunctions((firebase) {
    firestoreServiceAdminSdk.firestore(firebase.firebaseApp);

    // The function name is the Cloud Tasks queue name.
    // ignore: experimental_member_use
    firebase.tasks.onTaskDispatched(
      firebase.taskHandler(sendReportTaskHandler),
      name: 'send-report',
      options: const TaskQueueOptions(
        region: Region(SupportedRegion.europeWest1),
        retryConfig: TaskQueueRetryConfig(maxAttempts: MaxAttempts(2)),
        rateLimits: TaskQueueRateLimits(
          maxConcurrentDispatches: MaxConcurrentDispatches(5),
        ),
      ),
    );
    // The deployed name is derived from the topic.
    // ignore: experimental_member_use
    firebase.pubsub.onMessagePublished(
      firebase.pubsubHandler(eventsPubsubHandler),
      topic: 'my-topic',
      options: const PubSubOptions(region: Region(SupportedRegion.europeWest1)),
    );
  });
}
```

### Recording a task in firestore

```dart
import 'package:tekartik_firebase_firestore/firestore.dart';
import 'package:tekartik_firebase_functions_admin_sdk/functions_admin_sdk.dart';

/// Firestore must have been initialized in the `runFunctions` builder.
Future<void> recordTaskHandler(
  FirebaseFunctions firebaseFunctions,
  TaskRequest<Object?> request,
) async {
  var firestore = firebaseFunctions.app.getProduct<Firestore>()!;
  await firestore.collection('tasks').doc(request.id).set({
    'data': ?request.data,
    'queueName': request.queueName,
    'retryCount': request.retryCount,
    'executionCount': request.executionCount,
    'authUid': ?request.auth?.uid,
  });
}
```

### Enqueuing a task and publishing a message (emulator friendly)

```dart
import 'package:tekartik_firebase_admin_sdk/firebase_pubsub_admin_sdk.dart';
import 'package:tekartik_firebase_admin_sdk/firebase_tasks_admin_sdk.dart';
import 'package:tekartik_firebase_functions_admin_sdk/functions_admin_sdk.dart';

Future<CallableResult<Map<String, Object?>>> triggerHandler(
  FirebaseFunctions firebaseFunctions,
  CallableRequest<Object?> request,
  CallableResponse<Map<String, Object?>> response,
) async {
  var app = firebaseFunctions.app;
  var isEmulator = (firebaseFunctions as FirebaseFunctionsAdminSdk).isEmulator;

  var queue = firebaseTasksServiceAdminSdk.taskQueue(
    app,
    'send-report',
    region: 'europe-west1',
  );
  await queue.enqueue(
    {'reportId': 'r1'},
    options: FirebaseTaskEnqueueOptions(
      // The emulator cannot resolve the production url.
      uri: isEmulator
          ? 'http://localhost:5001/${app.options.projectId}'
                '/europe-west1/send-report'
          : null,
    ),
  );

  var topic = firebasePubsubServiceAdminSdk.topic(app, 'my-topic');
  var messageId = await topic.publish({'type': 'report_requested'});
  return CallableResult({'messageId': messageId});
}
```

### Simulating a Pub/Sub delivery

```dart
import 'dart:convert';

import 'package:tekartik_firebase_functions_admin_sdk/functions_admin_sdk.dart';

/// The json body Pub/Sub POSTs to a message published function.
Map<String, Object?> buildBody() {
  var body = pubsubMessagePublishedCloudEventJson(
    projectId: 'demo-project',
    topic: 'my-topic',
    // The payload is base64 encoded.
    data: base64Encode(utf8.encode(jsonEncode({'my': 'data'}))),
    attributes: {'v': '1'},
    messageId: '1',
  );
  assert(body['type'] == pubsubMessagePublishedEventType);
  return body;
}
```
