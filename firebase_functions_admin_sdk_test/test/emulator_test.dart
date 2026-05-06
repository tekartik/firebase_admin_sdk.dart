// ignore_for_file: depend_on_referenced_packages

@TestOn('vm')
library;

import 'dart:io';
import 'package:http/http.dart';
import 'package:path/path.dart';
import 'package:tekartik_firebase_emulator/firebase_emulator.dart';
import 'package:tekartik_firebase_functions_admin_sdk/functions_admin_sdk.dart';
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

var defaultRegion = regionUsCentral1;
var _emulatorService = FirebaseEmulatorService(path: '.');
Future main() async {
  if (await _emulatorService.isSupported()) {
    stdout.writeln('firebase emulator is supported');
  } else {
    test('not_supported', () {}, skip: 'firebase emulator is not supported');
    return;
  }
  final fbProjectId = await _emulatorService.getProjectId();
  group('firebase_functions_node', () {
    late FirebaseEmulator emulator;

    var baseUrl = 'http://localhost:5001/$fbProjectId/$defaultRegion';
    setUpAll(() async {
      var emulatorService = FirebaseEmulatorService(path: '.');
      emulator = await emulatorService.start(
        options: FirebaseEmulatorOptions(
          onlyFunctions: true,
          projectId: fbProjectId,
          debug: false,
        ),
      );
      // ✔  functions[us-central1-helloworldgcfdartv1]: http function initialized (http://127.0.0.1:5001/tekartik-eu-dev/us-central1/helloworldgcfdartv1).
      // ✔  functions[us-central1-prvinfogcfdartv1]: http function initialized (http://127.0.0.1:5001/tekartik-eu-dev/us-central1/prvinfogcfdartv1).
      // ✔  functions[us-central1-dartv1echo]: http function initialized (http://127.0.0.1:5001/tekartik-eu-dev/us-central1/dartv1echo).
      //                                                                  http://localhost:5001/tekartik-eu-dev/us-central1/echo
    });

    /// Most basic
    test('helloWorld', () async {
      var result = await read(Uri.parse(url.join(baseUrl, 'hello-world')));
      // ignore: avoid_print
      print('helloWorld: $result');
    });

    tearDownAll(() async {
      await emulator.stop();
    });
  }, timeout: const Timeout(Duration(minutes: 5)));
}
