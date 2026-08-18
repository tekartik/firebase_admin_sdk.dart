@TestOn('vm')
library;

import 'dart:io';
import 'package:path/path.dart';
import 'package:tekartik_app_http/app_http.dart';
import 'package:tekartik_firebase_emulator/firebase_emulator.dart';
import 'package:tekartik_firebase_functions_admin_sdk_test/emulator_test_context.dart';
import 'package:tekartik_firebase_functions_admin_sdk_test/functions_test_runner.dart';
import 'package:tekartik_firebase_functions_call_http/functions_call_http.dart';
import 'package:tekartik_firebase_functions_test/firebase_functions_test_runner.dart';
import 'package:tekartik_firebase_local/firebase_local.dart';
import 'package:test/test.dart';

var defaultRegion = regionBelgium;
var _emulatorService = FirebaseEmulatorService(path: '.');
Future main() async {
  if (await _emulatorService.isSupported()) {
    stdout.writeln('firebase emulator is supported');
  } else {
    test('not_supported', () {}, skip: 'firebase emulator is not supported');
    return;
  }
  // Force re-generation of functions.yaml
  var file = File(join('functions', 'functions.yaml'));
  if (file.existsSync()) {
    await file.delete();
  }
  final fbProjectId = await _emulatorService.getProjectId();

  var testContext = FirebaseFunctionsAdminSdkEmulatorTestContext(
    region: regionBelgium,
    emulatorOptions: FirebaseEmulatorOptions(
      onlyFunctions: true,
      onlyAuth: true,
      onlyFirestore: true,
      projectId: fbProjectId,
      debug: false,
    ),
  );
  var prefix = 'adminsdk';
  group('firebase_functions_dart', () {
    late FirebaseFunctionsTestClientContext testClientContext;
    setUpAll(() async {
      await testContext.setUpAll();

      var app = newFirebaseAppMemory(
        options: FirebaseAppOptions(projectId: fbProjectId),
      );
      var firebaseFunctionsCall = firebaseFunctionsCallServiceHttp
          .functionsCall(
            app,
            options: FirebaseFunctionsCallOptions(region: regionBelgium),
          );

      testClientContext = FirebaseFunctionsTestClientContext.urlTemplate(
        httpClientFactory: httpClientFactoryIo,
        urlTemplate: testContext.httpsUri('${prefix}__function__').toString(),
        functionsCall: firebaseFunctionsCall,
      );
    });
    tearDownAll(() async {
      await testContext.tearDownAll();
      await testClientContext.close();
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
    basicTestGroup(() => testClientContext);
  }, timeout: const Timeout(Duration(minutes: 5)));
}
