import 'package:cv/cv.dart';
import 'package:dev_test/dev_test.dart';
import 'package:tekartik_firebase_functions_call/functions_call.dart';

import 'src/constants.dart';

export 'package:tekartik_firebase_functions/firebase_functions.dart';

export 'src/constants.dart';

/// Test
abstract class FirebaseFunctionsAdminSdkCallTestClientContext {
  /// Functions call to use
  FirebaseFunctionsCall get functionsCall;

  /// For https requests and calls
  Uri httpsUri(String name);

  /// Client test context
  factory FirebaseFunctionsAdminSdkCallTestClientContext({
    required FirebaseFunctionsCall functionsCall,

    /// Example 'https://{{function}}-xxxxxxxx-ew.a.run.app'
    required String baseUrl,
  }) => _FirebaseFunctionsCallTestClientContext(
    functionsCall: functionsCall,
    baseUrl: baseUrl,
  );
}

class _FirebaseFunctionsCallTestClientContext
    implements FirebaseFunctionsAdminSdkCallTestClientContext {
  final String baseUrl;
  @override
  Uri httpsUri(String name) =>
      Uri.parse(baseUrl.replaceAll('{{function}}', name));
  @override
  final FirebaseFunctionsCall functionsCall;

  _FirebaseFunctionsCallTestClientContext({
    required this.functionsCall,
    required this.baseUrl,
  });
}

/// Adming sdk call test group
void ffAdminSdkCallTestGroup({
  required FirebaseFunctionsAdminSdkCallTestClientContext testContext,
}) {
  group('testFunction', () {
    group('call $testDartFunctionCallV1', () {
      late FirebaseFunctionsCallable functionsCallable;

      setUpAll(() async {
        functionsCallable = testContext.functionsCall.callableFromUri(
          testContext.httpsUri(testDartFunctionCallV1),
        );
      });

      test('hello', () async {
        var result = await functionsCallable.call<Model>({'test': 'Hello'});
        expect(result.data, {
          'data': {'test': 'Hello'},
        });
      });
    });
  });
}
