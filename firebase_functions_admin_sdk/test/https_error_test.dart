@TestOn('vm')
library;

import 'package:tekartik_firebase_functions_admin_sdk/functions_admin_sdk.dart';
import 'package:test/test.dart';

void main() async {
  // Allow test on the web
  test('FirebaseFunctionsHttpsErrorAdminSdkExt', () {
    var ffError = FirebaseFunctionsHttpsError(
      FirebaseFunctionsHttpsErrorCode.invalidArgument,
      'message',
      {'key': 'value'},
    );
    expect(ffError.code, FirebaseFunctionsHttpsErrorCode.invalidArgument);
    var adminSdkError = ffError.toAdminSdk();
    expect(adminSdkError.code, FunctionsErrorCode.invalidArgument);
    expect(adminSdkError.message, 'message');
    expect(adminSdkError.details, {'key': 'value'});
    expect(adminSdkError, isA<InvalidArgumentError>());
  });
}
