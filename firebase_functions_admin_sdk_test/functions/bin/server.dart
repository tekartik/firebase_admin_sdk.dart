import 'package:tekartik_firebase_admin_sdk/firebase_auth_admin_sdk.dart';
import 'package:tekartik_firebase_admin_sdk/firestore_admin_sdk.dart';
import 'package:tekartik_firebase_functions_admin_sdk/functions_admin_sdk.dart';
import 'package:tekartik_firebase_functions_admin_sdk_test/functions.dart';

void main(List<String> args) {
  testFunctionsApiInitBuilders();

  runFunctions((firebase) {
    // Init needed services
    var app = firebase.firebaseApp;
    firebaseAuthServiceAdminSdk.auth(app);
    firestoreServiceAdminSdk.firestore(app);

    // https://firebase.google.com/docs/functions/http-events
    firebase.https.onRequest(
      firebase.httpsHandler(functionsHttpV1Handler),
      name: testDartFunctionHttpsV1,
      options: const HttpsOptions(
        cors: Cors(['*']),
        // Set maxInstances to control costs during unexpected traffic spikes.
        // https://firebase.google.com/docs/functions/manage-functions#min-max-instances
        maxInstances: Instances(11),
        region: Region(SupportedRegion.europeWest1),
        timeoutSeconds: TimeoutSeconds(19),
      ),
    );
    firebase.https.onCall(
      firebase.callHandler(functionsCallV1Handler),
      name: testDartFunctionCallV1,
      options: const CallableOptions(
        cors: Cors(['*']),
        region: Region(SupportedRegion.europeWest1),
      ),
    );
    // Task dispatched function, enqueued through Cloud Tasks.
    // ignore: experimental_member_use
    firebase.tasks.onTaskDispatched(
      firebase.taskHandler(functionsTaskV1Handler),
      name: testDartFunctionTaskV1,
      options: const TaskQueueOptions(
        region: Region(SupportedRegion.europeWest1),
        retryConfig: TaskQueueRetryConfig(maxAttempts: MaxAttempts(2)),
        rateLimits: TaskQueueRateLimits(
          maxConcurrentDispatches: MaxConcurrentDispatches(5),
        ),
      ),
    );
    // Task dispatched function recording in firestore.
    // ignore: experimental_member_use
    firebase.tasks.onTaskDispatched(
      firebase.taskHandler(functionsTaskFirestoreV1Handler),
      name: testDartFunctionTaskFirestoreV1,
      options: const TaskQueueOptions(
        region: Region(SupportedRegion.europeWest1),
        retryConfig: TaskQueueRetryConfig(maxAttempts: MaxAttempts(2)),
      ),
    );
    // Pub/Sub triggered functions.
    // ignore: experimental_member_use
    firebase.pubsub.onMessagePublished(
      firebase.pubsubHandler(functionsPubsubV1Handler),
      topic: testDartPubsubTopicV1,
      options: const PubSubOptions(region: Region(SupportedRegion.europeWest1)),
    );
    // ignore: experimental_member_use
    firebase.pubsub.onMessagePublished(
      firebase.pubsubHandler(functionsPubsubFirestoreV1Handler),
      topic: testDartPubsubTopicFirestoreV1,
      options: const PubSubOptions(region: Region(SupportedRegion.europeWest1)),
    );
    firebase.https.onCall(
      firebase.callHandler(callBasicAdminSdkHandler),
      name: 'adminsdkbasic',
      options: const CallableOptions(
        cors: Cors(['*']),
        region: Region(SupportedRegion.europeWest1),
      ),
    );
  });
}
