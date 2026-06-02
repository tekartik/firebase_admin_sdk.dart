import 'package:tekartik_firebase_auth_local/auth_local.dart';
import 'package:tekartik_firebase_functions_admin_sdk_test/functions.dart';
import 'package:tekartik_firebase_functions_admin_sdk_test/functions_test_runner.dart';
import 'package:tekartik_firebase_functions_admin_sdk_test/http_test_context.dart';
import 'package:tekartik_firebase_local/firebase_local.dart';
import 'package:tekartik_http/http_memory.dart';
import 'package:test/test.dart';

Future main() async {
  var app = newFirebaseAppMemory();
  var authService = newAuthServiceLocal();
  authService.auth(app);

  var httpFactory = httpFactoryMemory;
  var testContext = FirebaseFunctionsAdminSdkHttpTestContext(
    app: app,
    declarer: declareRunner,
    httpFactory: httpFactory,
  );
  group('firebase_functions_dart', () {
    setUpAll(() async {
      await testContext.setUpAll();
    });
    tearDownAll(() async {
      await testContext.tearDownAll();
    });
    group('https', () {
      functionsHttpGroup(testContext);
    });
    group('call', () {
      functionsCallGroup(testContext);
    });
  });
}
