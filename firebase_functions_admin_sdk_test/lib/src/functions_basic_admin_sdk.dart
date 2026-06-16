import 'package:tekartik_firebase_admin_sdk/firebase_admin_sdk.dart';
import 'package:tekartik_firebase_functions_admin_sdk/functions_admin_sdk.dart';
import 'package:tekartik_firebase_functions_admin_sdk_http/functions_admin_sdk_http.dart';

/// Handler for the test call function.
Future<CallableResult<Object>> callBasicAdminSdkHandler(
  FirebaseFunctions firebaseFunctions,
  CallableRequest<Object?> request,
  CallableResponse<Object> response,
) async {
  var data = request.data;
  if (data is Map) {
    var command = data['command'];
    switch (command) {
      case 'echo':
        return CallableResult(data['data'] as Object);
      case 'not-found':
        throw NotFoundError('Not found', 'command $command');
      case 'project-id':
        return CallableResult(firebaseFunctions.app.projectId);
    }
    return CallableResult({'no': 'command'});
  }
  return CallableResult({'no': 'data'});
}

/// Declares the HTTP runner for admin SDK test functions.
void basicDeclareRunner(
  FirebaseFunctionsAdminSdkHttp functions, {
  required String prefix,
}) {
  functions.https.onAdminSdkCall('${prefix}basic', callBasicAdminSdkHandler);
}
