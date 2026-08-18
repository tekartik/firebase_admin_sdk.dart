import 'dart:convert';

import 'package:tekartik_firebase_functions_admin_sdk_test/functions.dart';
import 'package:tekartik_firebase_functions_admin_sdk_test/test_context.dart';
import 'package:tekartik_http/http.dart';

/// Calls the test call function with [data] and returns its result.
Future<Map<String, Object?>> callFunctionCommand(
  FirebaseFunctionsAdminSdkTestContext context,
  Map<String, Object?> data,
) async {
  var uri = context.httpsUri(testDartFunctionCallV1);
  var response = await httpClientSend(
    context.client,
    httpMethodPost,
    uri,
    headers: (HttpHeaders()..mimeType = httpContentTypeJson).toStringMap(),
    body: jsonEncode({'data': data}),
  );
  if (response.statusCode != httpStatusCodeOk) {
    throw StateError(
      'Call ${data['command']} failed ${response.statusCode} ${response.body}',
    );
  }
  var map = jsonDecode(response.body) as Map;
  return (map['result'] as Map).cast<String, Object?>();
}

/// Enqueues a task through the test call function.
///
/// The call function runs with the admin sdk credentials, so it can enqueue
/// the task in the Cloud Tasks queue of [functionName]. This is how a task is
/// enqueued when the functions are not run locally (emulator, deployed).
///
/// The target uri is explicitly specified as the Cloud Tasks emulator cannot
/// resolve the production function url.
Future<void> callFunctionEnqueueTask(
  FirebaseFunctionsAdminSdkTestContext context, {
  required String functionName,
  required Map<String, Object?> data,
  String? region,
}) async {
  await callFunctionCommand(context, {
    'command': testApiCommandTasksEnqueue,
    'name': functionName,
    'region': ?region,
    'uri': context.httpsUri(functionName).toString(),
    'data': data,
  });
}

/// Publishes a message through the test call function.
///
/// The call function runs with the admin sdk credentials, so it can publish
/// on the topic. This is how a message is published when the functions are
/// not run locally (emulator, deployed).
Future<void> callFunctionPublishMessage(
  FirebaseFunctionsAdminSdkTestContext context, {
  required String topic,
  required Map<String, Object?> data,
}) async {
  await callFunctionCommand(context, {
    'command': testApiCommandPubsubPublish,
    'topic': topic,
    'data': data,
  });
}

/// The pub/sub messages recorded in firestore, read through the test call
/// function.
Future<List<Map<String, Object?>>> callFunctionPubsubFirestoreList(
  FirebaseFunctionsAdminSdkTestContext context,
) async {
  var result = await callFunctionCommand(context, {
    'command': testApiCommandPubsubFirestoreList,
  });
  return ((result['messages'] as List?) ?? [])
      .map((item) => (item as Map).cast<String, Object?>())
      .toList();
}

/// Clears the pub/sub messages recorded in firestore, through the test call
/// function.
Future<void> callFunctionPubsubFirestoreClear(
  FirebaseFunctionsAdminSdkTestContext context,
) async {
  await callFunctionCommand(context, {
    'command': testApiCommandPubsubFirestoreClear,
  });
}

/// The tasks recorded in firestore, read through the test call function.
Future<List<Map<String, Object?>>> callFunctionTasksFirestoreList(
  FirebaseFunctionsAdminSdkTestContext context,
) async {
  var result = await callFunctionCommand(context, {
    'command': testApiCommandTasksFirestoreList,
  });
  return ((result['tasks'] as List?) ?? [])
      .map((item) => (item as Map).cast<String, Object?>())
      .toList();
}

/// Clears the tasks recorded in firestore, through the test call function.
Future<void> callFunctionTasksFirestoreClear(
  FirebaseFunctionsAdminSdkTestContext context,
) async {
  await callFunctionCommand(context, {
    'command': testApiCommandTasksFirestoreClear,
  });
}
