@TestOn('vm')
library;

import 'dart:io';
import 'package:http/http.dart';
import 'package:path/path.dart';
import 'package:tekartik_firebase_emulator/firebase_emulator.dart';
import 'package:test/test.dart';

var defaultRegion = 'europe-west1';
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
  group('firebase_functions_dart', () {
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
      expect(result, 'Hello from Dart Functions!');
    });

    tearDownAll(() async {
      await emulator.stop();
    });
  }, timeout: const Timeout(Duration(minutes: 5)));
}
