import 'dart:async';

import 'package:http/http.dart';
import 'package:path/path.dart';
import 'package:tekartik_firebase_emulator/firebase_emulator.dart';
import 'package:tekartik_firebase_functions_admin_sdk_test/test_context.dart';
import 'package:tekartik_firebase_functions_call/functions_call.dart';

/// Emulator test context for Firebase Functions Admin SDK.
class FirebaseFunctionsAdminSdkEmulatorTestContext
    implements FirebaseFunctionsAdminSdkTestContext {
  /// Firebase emulator options.
  final FirebaseEmulatorOptions emulatorOptions;

  /// Region for the functions.
  final String? region;

  var _refCount = 0;
  FirebaseEmulator? _emulator;

  late final _baseUrl =
      'http://localhost:5001/${emulatorOptions.projectId}/${region ?? regionUsCentral1}';

  /// Creates an emulator test context.
  FirebaseFunctionsAdminSdkEmulatorTestContext({
    required this.emulatorOptions,
    this.region,
  });
  @override
  Future<void> setUpAll() async {
    if (_refCount++ == 0) {
      var emulatorService = FirebaseEmulatorService(path: '.');
      _emulator = await emulatorService.start(options: emulatorOptions);
      // ✔  functions[us-central1-helloworldgcfdartv1]: http function initialized (http://127.0.0.1:5001/tekartik-eu-dev/us-central1/helloworldgcfdartv1).
      // ✔  functions[us-central1-prvinfogcfdartv1]: http function initialized (http://127.0.0.1:5001/tekartik-eu-dev/us-central1/prvinfogcfdartv1).
      // ✔  functions[us-central1-dartv1echo]: http function initialized (http://127.0.0.1:5001/tekartik-eu-dev/us-central1/dartv1echo).
      //                                                                  http://localhost:5001/tekartik-eu-dev/us-central1/echo
    }
  }

  @override
  Future<void> tearDownAll() async {
    if (--_refCount == 0) {
      await _emulator?.stop();
    }
  }

  @override
  Uri httpsUri(String path) {
    return Uri.parse(url.join(_baseUrl, path));
  }

  @override
  var client = Client();
}
