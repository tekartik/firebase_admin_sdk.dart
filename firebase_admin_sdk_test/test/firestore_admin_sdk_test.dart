library;

import 'package:tekartik_firebase_admin_sdk/firebase_admin_sdk.dart';
import 'package:tekartik_firebase_admin_sdk/firestore_admin_sdk.dart';
import 'package:test/test.dart';

var firebase = firebaseAdminSdk;
var firestoreService = firestoreServiceAdminSdk;

void testAppOnly(
  FirebaseApp Function() getApp,
  Firestore Function() getFirestore,
) {
  late Firestore firestore;
  late FirebaseApp app;
  setUpAll(() {
    app = getApp();
    firestore = getFirestore();
  });
  test('app', () {
    expect(firestore.app, app);
    expect(firestore.service, firestoreService);
    expect(firestoreService.firestore(app), firestore);
    expect(app.getProduct<Firestore>(), firestore);
  });
  test('doc', () {
    var doc = firestore.doc('test/doc');
    expect(doc.path, 'test/doc');
  });
  test('coll', () {
    var coll = firestore.collection('test');
    expect(coll.path, 'test');
  });
}

void main() {
  group('admin_sdk', () {
    late Firestore firestore;
    late FirebaseApp app;
    setUpAll(() {
      // No credentials needed for these tests (no request is sent).
      app = firebase.initializeApp(
        options: AppOptions(projectId: 'demo-firestore-admin-sdk-test'),
        name: 'firestore_admin_sdk_test',
      );
      firestore = firestoreService.firestore(app);
    });
    tearDownAll(() async {
      await app.delete();
    });
    testAppOnly(() => app, () => firestore);

    test('isLocal', () {
      expect(app.isLocal, isFalse);
      expect(firestore.service.supportsBlobs, isTrue);
    });
  });
}
