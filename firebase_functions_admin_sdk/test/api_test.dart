// ignore_for_file: unnecessary_statements

library;

import 'package:tekartik_common_utils/env_utils.dart';
import 'package:tekartik_firebase_functions_admin_sdk/functions_admin_sdk.dart';
import 'package:test/test.dart';

void main() async {
  // Allow test on the web
  test('firebaseFunctionsServiceAdminSdk', () {
    if (!kDartIsWeb) {
      firebaseFunctionsServiceAdminSdk;
    }
  });
}
