library;

import 'package:tekartik_firebase_admin_sdk/firebase_admin_sdk.dart';
import 'package:tekartik_firebase_admin_sdk/firestore_admin_sdk.dart';
import 'package:test/test.dart';

var firebase = firebaseAdminSdk;
var firestoreService = firestoreServiceAdminSdk;

void testAppOnly(Firestore Function() getFirestore) {
  late Firestore firestore;
  setUpAll(() {
    firestore = getFirestore();
  });
  test('app', () {
    var app = firestore.app;
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
    // there is no name on node
    setUpAll(() {
      app = firebase.initializeApp();
      firestore = firestoreService.firestore(app);
    });
    tearDownAll(() async {
      await app.delete();
    });
    testAppOnly(() => firestore);

    test('isLocal', () {
      expect(firestore.service.supportsBlobs, isFalse);
    });
  });
}
