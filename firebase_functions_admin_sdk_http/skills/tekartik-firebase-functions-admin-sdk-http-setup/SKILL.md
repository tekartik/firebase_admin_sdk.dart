---
name: tekartik-firebase-functions-admin-sdk-http-setup
description: >-
  Use when running admin sdk Cloud Functions handlers on a plain local http
  server (tests, dev server, no firebase emulator) with
  tekartik_firebase_functions_admin_sdk_http: FirebaseFunctionsServiceAdminSdkHttp,
  newFirebaseFunctionsServiceAdminSdkHttp, firebaseAdminServiceAdminSdkHttp,
  fireUp, FirebaseFunctionsAdminSdkHttp, httpServer, https.onAdminSdkRequest,
  https.onAdminSdkCall, tasks.onAdminSdkTaskDispatched,
  pubsub.onAdminSdkMessagePublished, functionNameForTopic, httpServerFactoryMemory.
---

# Local http functions server (tekartik_firebase_functions_admin_sdk_http)

Hosts the handlers written for `tekartik_firebase_functions_admin_sdk` on a
plain `tekartik_http` server (in memory or IO), one url path per function, so
tests and dev runs need neither the firebase emulator nor a deployment.

## Guidelines

* Depend on it with git (not on pub.dev):

  ```yaml
  dependencies:
    tekartik_firebase_functions_admin_sdk_http:
      git:
        url: https://github.com/tekartik/firebase_admin_sdk.dart
        path: firebase_functions_admin_sdk_http
  ```

  Single import:
  `import 'package:tekartik_firebase_functions_admin_sdk_http/functions_admin_sdk_http.dart';`.
  It does **not** re-export `functions_admin_sdk.dart`: import that too for
  `Request`, `Response`, `CallableRequest`, `CallableResult`, `TaskRequest`,
  `CloudEvent`, `PubsubMessage`.

* Create the service with `FirebaseFunctionsServiceAdminSdkHttp(httpServerFactory:)`
  (or the identical `newFirebaseFunctionsServiceAdminSdkHttp(...)`), then
  `await service.fireUp(app, (functions) { ... })`. `fireUp` first calls the
  runner (`TekartikFirebaseFunctionsAdminSdkHttpRunner`, which registers the
  functions) and only then binds and serves, so registration must be complete
  when the runner returns. `fireUp` never completes early but returns once the
  server listens; the request loop runs in the background.

* `httpServerFactory` defaults to `httpServerFactoryMemory` (from
  `package:tekartik_http/http_memory.dart`), which is what the shared
  singleton `firebaseAdminServiceAdminSdkHttp` uses: perfect for tests, no
  real socket. For a real server pass `httpServerFactoryIo` (add
  `tekartik_http_io` to your dependencies). The port is the
  `tekartik_firebase_functions_http` default; read the effective one from
  `functions.httpServer.port`, or build urls with `httpServerGetUri(server)`
  from `package:tekartik_http/http_server.dart`.

* The `app` passed to `fireUp` is any `tekartik_firebase` `FirebaseApp`: use
  `newFirebaseAppMemory()` from `package:tekartik_firebase_local/firebase_local.dart`
  in tests, or a real `firebaseAdminSdk.initializeApp(...)` app when the
  handlers need firestore/auth. Handlers get it through
  `firebaseFunctions.app`.

* Registration methods take the **function name first** and that name is the
  first url path segment (`http://host:port/<name>`):
  - `functions.https.onAdminSdkRequest(name, handler)` — raw http, the handler
    receives a `Request` whose uri is rewritten to `/<name>/...`, and returns
    a `Response`.
  - `functions.https.onAdminSdkCall<T>(name, handler)` — callable: `POST` a
    `{'data': ...}` json body; the result of `CallableResult<T>` is written
    back. A thrown `HttpResponseException` (i.e.
    `FirebaseFunctionsHttpsError(...).toAdminSdk()`) is serialized with its
    status code, anything else becomes a `500 INTERNAL`. The caller's uid is
    read from the `firebaseFunctionsHttpHeaderUid` header, exposed as
    `request.auth?.uid`.
  - `functions.tasks.onAdminSdkTaskDispatched(name, handler)` — `POST` a
    `{'data': ...}` json body, answered with `204`
    (`taskDispatchedNoContentStatusCode`). The `X-CloudTasks-*` headers
    (`cloudTasksHeaderQueueName`, `cloudTasksHeaderTaskName`,
    `cloudTasksHeaderTaskRetryCount`, ...) fill `TaskRequest`; missing ones
    default to the function name and an auto-incremented id.
  - `functions.pubsub.onAdminSdkMessagePublished(name, topic:, handler:)` —
    `POST` the cloud event json built by
    `pubsubMessagePublishedCloudEventJson(...)`, answered with `200`.
    `functions.pubsub.functionNameForTopic(topic)` gives back the local name
    (i.e. the path) and throws `StateError` for an unregistered topic.

* Anti-patterns: do not call the inherited abstract methods
  (`https.onRequest`, `https.onCall`, `tasks.onTaskDispatched`,
  `pubsub.onMessagePublished`) on this implementation, they throw
  `UnimplementedError` — always use the `onAdminSdk*` variants. There is no
  deployment path here: the deployed server is a `runFunctions` entry point
  built with `tekartik_firebase_functions_admin_sdk`. Write the handlers once
  in a shared library and register them twice.

* Shut down with `await functions.httpServer.close()` (keep the
  `FirebaseFunctionsAdminSdkHttp` the runner received). The ready made
  `FirebaseFunctionsAdminSdkHttpTestContext` of
  `tekartik_firebase_functions_admin_sdk_test` wraps all of this (setUpAll /
  tearDownAll, `httpsUri`, `publishMessage`, `enqueueTask`).

## Examples

### In-memory server with the four trigger kinds

```dart
import 'package:tekartik_firebase_functions_admin_sdk/functions_admin_sdk.dart';
import 'package:tekartik_firebase_functions_admin_sdk_http/functions_admin_sdk_http.dart';
import 'package:tekartik_firebase_local/firebase_local.dart';

Future<Response> helloHandler(
  FirebaseFunctions firebaseFunctions,
  Request request,
) async => Response.ok('Hello');

Future<CallableResult<Map<String, Object?>>> echoHandler(
  FirebaseFunctions firebaseFunctions,
  CallableRequest<Object?> request,
  CallableResponse<Map<String, Object?>> response,
) async => CallableResult({'echo': request.data, 'uid': request.auth?.uid});

Future<void> reportTaskHandler(
  FirebaseFunctions firebaseFunctions,
  TaskRequest<Object?> request,
) async => print('task ${request.id}: ${request.data}');

Future<void> eventsPubsubHandler(
  FirebaseFunctions firebaseFunctions,
  CloudEvent<PubsubMessage> event,
) async => print('message ${event.data!.jsonData}');

Future<FirebaseFunctionsAdminSdkHttp> startFunctions() async {
  var app = newFirebaseAppMemory();
  var service = FirebaseFunctionsServiceAdminSdkHttp();
  late FirebaseFunctionsAdminSdkHttp functions;
  await service.fireUp(app, (registered) {
    functions = registered;
    registered.https.onAdminSdkRequest('hello', helloHandler);
    registered.https.onAdminSdkCall('echo', echoHandler);
    registered.tasks.onAdminSdkTaskDispatched('send-report', reportTaskHandler);
    registered.pubsub.onAdminSdkMessagePublished(
      'on-events',
      topic: 'events',
      handler: eventsPubsubHandler,
    );
  });
  print('listening on ${functions.httpServer.port}');
  return functions;
}
```

### Calling the functions over http

```dart
import 'dart:convert';

import 'package:tekartik_firebase_functions_admin_sdk/functions_admin_sdk.dart';
import 'package:tekartik_firebase_functions_admin_sdk_http/functions_admin_sdk_http.dart';
import 'package:tekartik_http/http_client.dart';
import 'package:tekartik_http/http_memory.dart';
import 'package:tekartik_http/http_server.dart';

/// [functions] comes from a `fireUp` runner (memory server here).
Future<void> exercise(FirebaseFunctionsAdminSdkHttp functions) async {
  var baseUri = httpServerGetUri(functions.httpServer);
  var client = httpClientFactoryMemory.newClient();
  try {
    var hello = await httpClientRead(
      client,
      httpMethodGet,
      baseUri.replace(path: '/hello'),
    );
    print(hello);

    var echo = await httpClientRead(
      client,
      httpMethodPost,
      baseUri.replace(path: '/echo'),
      headers: {httpHeaderContentType: httpContentTypeJson},
      body: jsonEncode({
        'data': {'value': 1},
      }),
    );
    print(echo);

    // A task: `{'data': ...}` body, answered with 204.
    var taskResponse = await httpClientSend(
      client,
      httpMethodPost,
      baseUri.replace(path: '/send-report'),
      headers: {
        httpHeaderContentType: httpContentTypeJson,
        cloudTasksHeaderTaskRetryCount: '0',
      },
      body: jsonEncode({
        'data': {'reportId': 'r1'},
      }),
    );
    assert(taskResponse.statusCode == taskDispatchedNoContentStatusCode);
  } finally {
    client.close();
  }
}
```

### Simulating a Pub/Sub delivery

```dart
import 'dart:convert';

// For the `projectId` extension on `FirebaseApp`.
import 'package:tekartik_firebase/firebase.dart';
import 'package:tekartik_firebase_functions_admin_sdk/functions_admin_sdk.dart';
import 'package:tekartik_firebase_functions_admin_sdk_http/functions_admin_sdk_http.dart';
import 'package:tekartik_http/http_client.dart';
import 'package:tekartik_http/http_memory.dart';
import 'package:tekartik_http/http_server.dart';

Future<void> publishMessage(
  FirebaseFunctionsAdminSdkHttp functions,
  String topic,
  Map<String, Object?> data,
) async {
  // The url path is the registered function name, not the topic.
  var name = functions.pubsub.functionNameForTopic(topic);
  var uri = httpServerGetUri(functions.httpServer).replace(path: '/$name');
  var body = pubsubMessagePublishedCloudEventJson(
    projectId: functions.app.projectId,
    topic: topic,
    data: base64Encode(utf8.encode(jsonEncode(data))),
    messageId: '1',
  );
  var client = httpClientFactoryMemory.newClient();
  try {
    var response = await httpClientSend(
      client,
      httpMethodPost,
      uri,
      headers: {httpHeaderContentType: httpContentTypeJson},
      body: jsonEncode(body),
    );
    if (response.statusCode != httpStatusCodeOk) {
      throw StateError('publish failed ${response.statusCode}');
    }
  } finally {
    client.close();
  }
}
```
