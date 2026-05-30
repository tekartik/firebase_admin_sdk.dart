import 'dart:async';

import 'package:http/src/client.dart';
import 'package:path/path.dart';
import 'package:tekartik_firebase_emulator/firebase_emulator.dart';
import 'package:tekartik_firebase_functions_admin_sdk_test/test_context.dart';
import 'package:tekartik_firebase_functions_call/functions_call.dart';
import 'package:tekartik_http/http.dart';

class FirebaseFunctionsAdminSdkHttpTestContext
    implements FirebaseFunctionsAdminSdkTestContext {
  var _refCount = 0;
  final HttpClientFactory httpClientFactory;
  @override
  Future<void> setUpAll() async {
    // Start http server
  }

  @override
  Future<void> tearDownAll() async {
    if (--_refCount == 0) {
      client.close();
    }
  }

  @override
  Uri httpsUri(String path) => throw 'TODO';

  @override
  late final client = httpClientFactory.newClient();

  FirebaseFunctionsAdminSdkHttpTestContext({required this.httpClientFactory});
}
