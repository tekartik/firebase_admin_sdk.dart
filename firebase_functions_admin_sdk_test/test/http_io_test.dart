import 'package:tekartik_firebase_functions_admin_sdk_test/functions.dart';
import 'package:tekartik_firebase_functions_admin_sdk_test/functions_test.dart';
import 'package:tekartik_firebase_functions_admin_sdk_test/http_test_context.dart';
import 'package:tekartik_firebase_local/firebase_local.dart';
import 'package:test/test.dart';

Future main() async {
  var app = newFirebaseAppLocal();
  var testContext = FirebaseFunctionsAdminSdkHttpTestContext(
    app: app,
    declarer: declareRunner,
  );
  group('firebase_functions_dart', () {
    functionsHttpGroup(testContext);
  });
}
