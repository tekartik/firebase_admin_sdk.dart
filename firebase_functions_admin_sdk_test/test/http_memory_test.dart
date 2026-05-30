import 'package:tekartik_firebase_emulator/firebase_emulator.dart';
import 'package:tekartik_firebase_functions_admin_sdk_test/emulator_test_context.dart';
import 'package:tekartik_firebase_functions_admin_sdk_test/functions_test.dart';
import 'package:tekartik_firebase_functions_admin_sdk_test/http_test_context.dart';
import 'package:tekartik_firebase_functions_call/functions_call.dart';
import 'package:tekartik_http/http_memory.dart';
import 'package:test/test.dart';

var defaultRegion = regionBelgium;
var _emulatorService = FirebaseEmulatorService(path: '.');
Future main() async {
  final fbProjectId = 'fb_project_id';

  var httpFactory = httpFactoryMemory;
  var testContext = FirebaseFunctionsAdminSdkHttpTestContext(
    httpClientFactory: httpFactory.client,
  );
  group('firebase_functions_dart', () {
    functionsHttpGroup(testContext);
  });
}
