@TestOn('vm')
library;

import 'dart:io';
import 'package:path/path.dart';
import 'package:tekartik_firebase_emulator/firebase_emulator.dart';
import 'package:tekartik_firebase_functions_admin_sdk_test/emulator_test_context.dart';
import 'package:tekartik_firebase_functions_admin_sdk_test/functions_test_runner.dart';
import 'package:tekartik_firebase_functions_call/functions_call.dart';
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
      projectId: fbProjectId,
      debug: false,
    ),
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
  }, timeout: const Timeout(Duration(minutes: 5)));
}
