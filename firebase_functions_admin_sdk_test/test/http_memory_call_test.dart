library;

import 'package:tekartik_app_http/app_http.dart';
import 'package:tekartik_firebase_auth_local/auth_local.dart';
import 'package:tekartik_firebase_functions_admin_sdk_test/functions.dart';
import 'package:tekartik_firebase_functions_admin_sdk_test/functions_call_test_runner.dart';
import 'package:tekartik_firebase_functions_admin_sdk_test/http_test_context.dart';
import 'package:tekartik_firebase_functions_admin_sdk_test/test_context.dart';
import 'package:tekartik_firebase_functions_call_http/functions_call_memory.dart';
import 'package:tekartik_firebase_local/firebase_local.dart';
import 'package:test/test.dart';

void main() async {
  late FirebaseFunctionsAdminSdkCallTestClientContext testClientContext;
  late FirebaseFunctionsAdminSdkHttpTestContext testServerContext;

  setUpAll(() async {
    var httpFactory = httpFactoryMemory;
    var app = newFirebaseAppMemory();
    var prefix = 'adminsdkmemory';
    testServerContext = FirebaseFunctionsAdminSdkHttpTestContext(
      app: app,
      declarer: (functions) {
        declareRunner(functions, prefix: prefix);
      },
      httpFactory: httpFactory,
    );

    var auth = authServiceLocal.auth(app);
    var signInInfo = FirebaseFunctionsAdminSdkTestContextSignInInfo(
      auth: auth,
      email: 'test@example.com',
      password: 'password',
    );

    await auth.createUserWithEmailAndPassword(
      email: 'test@example.com',
      password: 'password',
    );
    await testServerContext.setUpAll();

    var firebaseFunctionsCall = firebaseFunctionsCallServiceMemory
        .functionsCall(
          app,
          options: FirebaseFunctionsCallOptions(region: regionBelgium),
        );

    testClientContext = FirebaseFunctionsAdminSdkCallTestClientContext(
      baseUrl: testServerContext.httpsUri('${prefix}__function__').toString(),
      functionsCall: firebaseFunctionsCall,
      signInInfo: signInInfo,
    );
  });
  test('uri', () {
    //expect(uri.toString(), 'http://_memory:${server.port}/adminsdkmemorybasic');
  });

  ffAdminSdkCallTestGroup(() => testClientContext);
  tearDownAll(() async {
    await testServerContext.tearDownAll();
    // await testClientContext.close();
  });
}
