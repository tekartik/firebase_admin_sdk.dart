library;

import 'package:tekartik_app_http/app_http.dart';
import 'package:tekartik_firebase_functions_admin_sdk_test/functions.dart';
import 'package:tekartik_firebase_functions_admin_sdk_test/http_test_context.dart';
import 'package:tekartik_firebase_functions_call_http/functions_call_memory.dart';
import 'package:tekartik_firebase_functions_test/firebase_functions_test_runner.dart';
import 'package:tekartik_firebase_local/firebase_local.dart';
import 'package:test/test.dart';

void main() async {
  late Uri uri;
  late HttpServer server;
  late FirebaseFunctionsTestClientContext testClientContext;
  late FirebaseFunctionsAdminSdkHttpTestContext testServerContext;

  setUpAll(() async {
    var httpFactory = httpFactoryMemory;
    var app = newFirebaseAppMemory();
    var prefix = 'adminsdkmemory';
    testServerContext = FirebaseFunctionsAdminSdkHttpTestContext(
      app: app,
      declarer: (functions) {
        basicDeclareRunner(functions, prefix: prefix);
      },
      httpFactory: httpFactory,
    );

    var httpClientFactory = httpClientFactoryMemory;

    await testServerContext.setUpAll();
    server = testServerContext.server;

    var firebaseFunctionsCall = firebaseFunctionsCallServiceMemory
        .functionsCall(
          app,
          options: FirebaseFunctionsCallOptions(region: regionBelgium),
        );

    testClientContext = FirebaseFunctionsTestClientContext.urlTemplate(
      httpClientFactory: httpClientFactory,
      urlTemplate: testServerContext
          .httpsUri('${prefix}__function__')
          .toString(),
      functionsCall: firebaseFunctionsCall,
    );

    uri = Uri.parse(testClientContext.url('basic'));
  });
  test('uri', () {
    expect(uri.toString(), 'http://_memory:${server.port}/adminsdkmemorybasic');
  });

  basicTestGroup(() => testClientContext);
  tearDownAll(() async {
    await testServerContext.tearDownAll();
    await testClientContext.close();
  });
}
