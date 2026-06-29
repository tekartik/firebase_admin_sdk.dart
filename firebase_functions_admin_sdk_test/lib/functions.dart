import 'dart:typed_data';

import 'package:cv/cv_json.dart';
import 'package:tekartik_common_utils/byte_utils.dart';
import 'package:tekartik_common_utils/common_utils_import.dart';
import 'package:tekartik_firebase_auth/auth.dart';
import 'package:tekartik_firebase_functions_admin_sdk/functions_admin_sdk.dart';

import 'package:tekartik_firebase_functions_admin_sdk_http/functions_admin_sdk_http.dart';
import 'package:tekartik_firebase_functions_admin_sdk_test/functions.dart';

import 'package:tekartik_http/http_client.dart';

export 'package:tekartik_firebase_functions_test/functions_basic.dart';
export 'src/constants.dart';
export 'src/functions_basic_admin_sdk.dart';

/// Auth users command
/// Get the first 10 uids
const testApiCommandAuthUsers = 'auth/users';

/// Auth current user command
const testApiCommandAuthMe = 'auth/me';

/// Echo command
///
const testApiCommandEcho = 'echo';

/// Declares the HTTP runner for admin SDK test functions.
void declareRunner(FirebaseFunctionsAdminSdkHttp functions, {String? prefix}) {
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
}

/// Handler for the test call function.
Future<CallableResult<Model>> functionsCallV1Handler(
  FirebaseFunctions firebaseFunctions,
  CallableRequest<Object?> request,
  CallableResponse<Model> response,
) async {
  var data = request.data;

  //print('headers: ${request.headers}')
  if (data is Map) {
    var apiRequest = data.cv<TestApiRequest>();
    var command = apiRequest.command.v;
    if (command != null) {
      switch (command) {
        case testApiCommandAuthUsers:
          var app = firebaseFunctions.app;

          var auth = app.getProduct<FirebaseAuth>()!;
          var listResult = await auth.listUsers(maxResults: 10);
          return CallableResult(
            asModel({
              'users': listResult.users
                  .map((record) => record?.uid)
                  .nonNulls
                  .toList(),
            }),
          );
        case testApiCommandAuthMe:
          var userId = request.auth?.uid;
          return CallableResult(asModel({'uid': userId}));
        case testApiCommandEcho:
          return CallableResult(Model.from({'data': data}));
      }
    }
  }
  return CallableResult(
    Model.from({
      'data': ?data,
      'authUid': ?request.auth?.uid,
      'instanceIdToken': ?request.instanceIdToken,
    }),
  );
}

/// Handler for the test functions.
Future<Response> functionsHttpV1Handler(
  FirebaseFunctions firebaseFunctions,
  Request request,
) async {
  var info =
      parseBool(
        request.url.queryParameters['info'] ??
            request.requestedUri.queryParameters['info'],
      ) ??
      false;
  if (info) {
    String? body;
    Uint8List? bodyBytes;
    var contentLength = request.contentLength;
    var mimeType = request.mimeType;
    if ((contentLength ?? 0) > 0) {
      try {
        if (mimeType != null && mimeType != httpContentTypeBytes) {
          body = await request.readAsString();
        } else {
          bodyBytes = await listStreamGetBytes(request.read());
        }
      } catch (_) {}
    }

    return Response.ok(
      {
        'url': request.url.toString(),
        'requestedUri': request.requestedUri.toString(),
        'method': request.method,
        'body': ?body,
        'bodyBytes': ?bodyBytes,
        'mimeType': ?mimeType,
        'contentLength': contentLength ?? 0,
        'protocolVersion': request.protocolVersion,
      }.cvToJson(),
    );
  }
  //print(request.url);
  //print(request.requestedUri);
  return Response.ok('Hello');
}
