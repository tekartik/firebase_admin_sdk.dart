@TestOn('vm')
library;

import 'package:tekartik_firebase_admin_sdk/firebase_admin_sdk.dart';
import 'package:tekartik_firebase_admin_sdk/firebase_pubsub_admin_sdk.dart';
import 'package:test/test.dart';

void main() {
  group('pubsub_admin_sdk', () {
    late FirebaseApp app;
    setUpAll(() {
      app = firebaseAdminSdk.initializeApp(
        options: AppOptions(projectId: 'test_project'),
      );
    });
    tearDownAll(() async {
      await app.delete();
    });
    test('topic', () {
      var topic = firebasePubsubServiceAdminSdk.topic(app, 'my-topic');
      expect(topic.name, 'my-topic');
    });
    test('emulator host', () {
      // Not running against the emulator in the tests.
      expect(pubsubEmulatorHost, isNull);
    });
    test('publish options', () {
      var options = const FirebasePubsubPublishOptions(
        attributes: {'key': 'value'},
        orderingKey: 'order',
      );
      expect(options.attributes, {'key': 'value'});
      expect(options.orderingKey, 'order');
    });
  });
}
