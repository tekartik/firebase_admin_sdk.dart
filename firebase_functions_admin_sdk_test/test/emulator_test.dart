// ignore_for_file: depend_on_referenced_packages

@TestOn('vm')
library;

import 'dart:io';
import 'package:http/http.dart';
import 'package:path/path.dart';
import 'package:tekartik_firebase_emulator/firebase_emulator.dart';
import 'package:tekartik_firebase_functions_admin_sdk/functions_admin_sdk.dart';
import 'package:tekartik_firebase_functions_admin_sdk_test/emulator_test_context.dart';
import 'package:tekartik_firebase_functions_admin_sdk_test/functions.dart';
import 'package:tekartik_firebase_functions_admin_sdk_test/functions_test.dart';
import 'package:tekartik_firebase_functions_call/functions_call.dart';
import 'package:test/test.dart';

/*
import 'package:firebase_node_test_gcf/src/constant.dart';
import 'package:firebase_node_test_gcf/src/import_common.dart';

import 'package:http/http.dart';
import 'package:path/path.dart';
import 'package:process_run/shell.dart';
import 'package:tekartik_firebase_admin_sdk_test_gcf/example.dart';
import 'package:tekartik_firebase_admin_sdk_test_gcf/src/constant.dart';
import 'package:tekartik_firebase_emulator/firebase_emulator.dart';
import 'package:tekartik_firebase_functions_http/test/firebase_functions_test_context_http.dart'
    as ff_test;
import 'package:tekartik_firebase_functions_test/firebase_functions_test.dart'
    as ff_test;
import 'package:test/test.dart';


*/

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
    functionsHttpGroup(testContext);
  }, timeout: const Timeout(Duration(minutes: 5)));
}
