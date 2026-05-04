library;

import 'package:tekartik_firebase/firebase_mixin.dart';
import 'package:tekartik_firebase_admin_sdk/firebase_admin_sdk.dart';
import 'package:tekartik_firebase_test/firebase_test.dart';
import 'package:test/test.dart';

void main() {
  group('admin_sdk', () {
    var firebase = firebaseAdminSdk;
    // there is no name on node
    group('firebase', () {
      runFirebaseTests(firebase, options: null);
      runFirebaseTests(
        firebase,
        options: AppOptions(projectId: 'test'),
        name: 'test',
      );
    });

    test('isLocal', () {
      expect(firebase.isLocal, isFalse);
    });

    test('initialize default and latest', () async {
      FirebaseMixin.latestFirebaseInstanceOrNull = null;
      var app = firebase.initializeApp();
      expect(FirebaseMixin.latestFirebaseInstanceOrNull, app);
      expect(app.name, '[DEFAULT]');
      //expect(app.projectId, 'test');
      await app.delete();
      //      expect(app.localPath, join(firebase.localPath!, 'test'));
    });

    test('initialize project id and latest', () async {
      FirebaseMixin.latestFirebaseInstanceOrNull = null;
      var app = firebase.initializeApp(options: AppOptions(projectId: 'test'));
      expect(FirebaseMixin.latestFirebaseInstanceOrNull, app);
      expect(app.name, '[DEFAULT]');
      expect(app.projectId, 'test');
      await app.delete();
      //      expect(app.localPath, join(firebase.localPath!, 'test'));
    });
    test('projectId', () async {
      var app = await firebase.initializeAppAsync(
        options: AppOptions(projectId: 'test'),
      );
      expect(app.options.projectId, 'test');
      await app.delete();
    });
  });
}
