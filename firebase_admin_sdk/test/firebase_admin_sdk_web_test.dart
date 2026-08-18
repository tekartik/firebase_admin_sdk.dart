@TestOn('browser')
library;

import 'package:tekartik_firebase_admin_sdk/firebase_admin_sdk.dart';
import 'package:test/test.dart';

void main() {
  group('admin_sdk', () {
    test('web', () {
      expect(() => firebaseAdminSdk, throwsA(isA<UnsupportedError>()));
    });
  });
}
