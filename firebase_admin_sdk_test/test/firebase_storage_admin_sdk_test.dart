library;

import 'package:tekartik_firebase_admin_sdk/firebase_admin_sdk.dart';
import 'package:tekartik_firebase_admin_sdk/firebase_storage_admin_sdk.dart';
import 'package:tekartik_firebase_storage_test/storage_test.dart';
import 'package:test/test.dart';

void main() {
  group('storage_admin_sdk', () {
    var firebase = firebaseAdminSdk;
    var storageService = firebaseStorageServiceAdminSdk;

    group('app', () {
      late FirebaseApp app;
      setUpAll(() {
        app = firebase.initializeApp();
      });
      tearDownAll(() async {
        await app.delete();
      });

      test('app', () {
        var storage = storageService.storage(app);
        expect(storage.app, app);
        expect(storage.service, storageService);
        expect(storageService.storage(app), storage);
        expect(app.getProduct<FirebaseStorage>(), storage);
      });
    });

    runStorageTests(
      firebase: firebase,
      storageService: storageService,
      storageOptions: TestStorageOptions(),
    );
  }, skip: true);
}
