import 'package:cv/cv_json.dart';
import 'package:dev_test/dev_test.dart';
import 'package:tekartik_common_utils/common_utils_import.dart';
import 'package:tekartik_firebase_functions_admin_sdk_test/functions.dart';
import 'package:tekartik_firebase_functions_admin_sdk_test/test_context.dart';
import 'package:tekartik_firebase_functions_call/functions_call.dart';

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

    FirebaseFunctionsAdminSdkTestContextSignInInfo? signInInfo,
  }) => _FirebaseFunctionsCallTestClientContext(
    functionsCall: functionsCall,
    baseUrl: baseUrl,
    signInInfo: signInInfo,
  );

  /// Sign in info
  FirebaseFunctionsAdminSdkTestContextSignInInfo? get signInInfo;
}

class _FirebaseFunctionsCallTestClientContext
    implements FirebaseFunctionsAdminSdkCallTestClientContext {
  final String baseUrl;
  @override
  final FirebaseFunctionsAdminSdkTestContextSignInInfo? signInInfo;
  @override
  Uri httpsUri(String name) => Uri.parse(
    baseUrl.replaceAll('{{function}}', name).replaceAll('__function__', name),
  );
  @override
  final FirebaseFunctionsCall functionsCall;

  _FirebaseFunctionsCallTestClientContext({
    this.signInInfo,
    required this.functionsCall,
    required this.baseUrl,
  });
}

/// Adming sdk call test group
void ffAdminSdkCallTestGroup(
  FutureOr<FirebaseFunctionsAdminSdkCallTestClientContext> Function() init,
) {
  group('testFunction', () {
    group('call $testDartFunctionCallV1', () {
      late FirebaseFunctionsCallable functionsCallable;
      late FirebaseFunctionsAdminSdkCallTestClientContext testContext;

      setUpAll(() async {
        testContext = await init();
        functionsCallable = testContext.functionsCall.callableFromUri(
          testContext.httpsUri(testDartFunctionCallV1),
        );
      });

      test('echo', () async {
        var request = TestApiRequest()..command.v = testApiCommandEcho;
        var result = await functionsCallable.call<Model>(request.toMap());
        expect(result.data, {
          'data': {'command': 'echo'},
        });
      });

      test('auth/me', () async {
        var signInInfo = testContext.signInInfo;
        String? userId;
        if (signInInfo != null) {
          var user = await signInInfo.auth.signInWithEmailAndPassword(
            email: signInInfo.email,
            password: signInInfo.password,
          );
          userId = user.user.uid;
        }

        Future<String?> getUserId() async {
          var request = TestApiRequest()..command.v = testApiCommandAuthMe;
          var response = await functionsCallable.call<Model>(request.toMap());
          var result = response.data;

          // ignore: avoid_print
          print('result: ${result.cvToJsonPretty()}');
          return result['uid'] as String?;
        }

        var readUid = await getUserId();
        if (signInInfo != null) {
          expect(readUid, isNotNull);

          expect(readUid, userId);
          await signInInfo.auth.signOut();

          readUid = await getUserId();

          expect(readUid, isNull);
        }
      });
    });
  });
}
