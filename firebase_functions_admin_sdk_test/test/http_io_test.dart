import 'package:tekartik_firebase_auth_local/auth_local.dart';
import 'package:tekartik_firebase_firestore_sembast/firestore_sembast.dart';
import 'package:tekartik_firebase_functions_admin_sdk_test/functions.dart';
import 'package:tekartik_firebase_functions_admin_sdk_test/functions_test_runner.dart';
import 'package:tekartik_firebase_functions_admin_sdk_test/http_test_context.dart';
import 'package:tekartik_firebase_local/firebase_local.dart';
import 'package:test/test.dart';

Future main() async {
  var app = newFirebaseAppLocal();
  var authService = newAuthServiceLocal();
  authService.auth(app);
  newFirestoreServiceMemory().firestore(app);
  var testContext = FirebaseFunctionsAdminSdkHttpTestContext(
    app: app,
    declarer: declareRunner,
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
    group('tasks', () {
      functionsTaskGroup(testContext);
    });
    group('tasks firestore', () {
      functionsTaskFirestoreGroup(testContext);
    });
  });
}
