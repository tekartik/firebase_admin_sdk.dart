import 'dart:convert';

import 'package:tekartik_firebase_functions_admin_sdk_test/functions.dart';
import 'package:tekartik_firebase_functions_admin_sdk_test/test_context.dart';
import 'package:tekartik_http/http.dart';

/// Enqueues a task through the test call function.
///
/// The call function runs with the admin sdk credentials, so it can enqueue
/// the task in the Cloud Tasks queue of [functionName]. This is how a task is
/// enqueued when the functions are not run locally (emulator, deployed).
///
/// The target [uri] is explicitly specified as the Cloud Tasks emulator
/// cannot resolve the production function url.
Future<void> callFunctionEnqueueTask(
  FirebaseFunctionsAdminSdkTestContext context, {
  required String functionName,
  required Map<String, Object?> data,
  String? region,
}) async {
  var uri = context.httpsUri(testDartFunctionCallV1);
  var response = await httpClientSend(
    context.client,
    httpMethodPost,
    uri,
    headers: (HttpHeaders()..mimeType = httpContentTypeJson).toStringMap(),
    body: jsonEncode({
      'data': {
        'command': testApiCommandTasksEnqueue,
        'name': functionName,
        'region': ?region,
        'uri': context.httpsUri(functionName).toString(),
        'data': data,
      },
    }),
  );
  if (response.statusCode != httpStatusCodeOk) {
    throw StateError(
      'Enqueue task failed ${response.statusCode} ${response.body}',
    );
  }
}
