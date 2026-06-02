// ignore_for_file: unnecessary_statements

import 'package:tekartik_common_utils/env_utils.dart';
import 'package:tekartik_firebase_admin_sdk/firebase_admin_sdk.dart';
import 'package:tekartik_firebase_admin_sdk/firebase_auth_admin_sdk.dart';
import 'package:tekartik_firebase_admin_sdk/firebase_storage_admin_sdk.dart';
import 'package:tekartik_firebase_admin_sdk/firestore_admin_sdk.dart';
import 'package:test/test.dart';

void main() {
  test('api_test', () {
    if (!kDartIsWeb) {
      firebaseAdminSdk;
      firebaseAuthServiceAdminSdk;
      firebaseStorageServiceAdminSdk;
      firestoreServiceAdminSdk;
    } else {
      try {
        firebaseAdminSdk.initializeAppWithServiceAccountMap({});
      } catch (_) {}
    }
    FirebaseAdminSdk;
    FirebaseAppAdminSdk;
  });
}
