import 'package:tekartik_firebase_auth_local/auth_local.dart';
import 'package:tekartik_firebase_firestore_sembast/firestore_sembast.dart';
import 'package:tekartik_firebase_functions_admin_sdk_test/functions.dart';
import 'package:tekartik_firebase_functions_admin_sdk_test/functions_test_runner.dart';
import 'package:tekartik_firebase_functions_admin_sdk_test/http_test_context.dart';
import 'package:tekartik_firebase_functions_admin_sdk_test/test_context.dart';
import 'package:tekartik_firebase_local/firebase_local.dart';
import 'package:tekartik_http/http_memory.dart';
import 'package:test/test.dart';

Future main() async {
  var app = newFirebaseAppMemory();
  var authService = newAuthServiceLocal();
  var auth = authService.auth(app);
  newFirestoreServiceMemory().firestore(app);

  var signInInfo = FirebaseFunctionsAdminSdkTestContextSignInInfo(
    auth: auth,
    email: 'test@example.com',
    password: 'password',
  );
  await auth.signInOrUpWithEmailAndPassword(
    email: signInInfo.email,
    password: signInInfo.password,
  );
  await auth.signOut();
  var httpFactory = httpFactoryMemory;

  var testContext = FirebaseFunctionsAdminSdkHttpTestContext(
    app: app,
    declarer: declareRunner,
    httpFactory: httpFactory,
    signInInfo: signInInfo,
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
