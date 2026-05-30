import 'dart:typed_data';

import 'package:cv/cv_json.dart';
import 'package:tekartik_common_utils/byte_utils.dart';
import 'package:tekartik_common_utils/common_utils_import.dart';
import 'package:tekartik_firebase_functions_admin_sdk/functions_admin_sdk.dart';
import 'package:tekartik_firebase_functions_admin_sdk_http/functions_admin_sdk_http.dart';
import 'package:tekartik_http/http_client.dart';

/// https function
const testFunctionHttpsV1 = 'admin-sdk-https-v1';

/// Declares the HTTP runner for admin SDK test functions.
void declareRunner(FirebaseFunctionsAdminSdkHttp functions) {
  functions.https.onAdminSdkRequest(
    testFunctionHttpsV1,
    functionsHttpV1Handler,
  );
}

/// Handler for the test functions.
Future<Response> functionsHttpV1Handler(
  FirebaseFunctionsAdminSdk firebaseFunctions,
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
