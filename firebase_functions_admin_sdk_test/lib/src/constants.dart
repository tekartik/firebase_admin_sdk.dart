/// https function
const testDartFunctionHttpsV1 = 'admin-sdk-https-v1';

/// call function
const testDartFunctionCallV1 = 'admin-sdk-call-v1';

/// Task dispatched function
const testDartFunctionTaskV1 = 'admin-sdk-task-v1';

/// Task dispatched function recording in firestore
const testDartFunctionTaskFirestoreV1 = 'admin-sdk-task-firestore-v1';

/// Firestore collection where [testDartFunctionTaskFirestoreV1] records the
/// tasks it receives.
const testTasksFirestoreCollectionPath = 'tests_admin_sdk_tasks';

/// Pub/Sub triggered function (recording in a local file)
const testDartFunctionPubsubV1 = 'admin-sdk-pubsub-v1';

/// Topic of [testDartFunctionPubsubV1]
const testDartPubsubTopicV1 = 'admin-sdk-topic-v1';

/// Pub/Sub triggered function recording in firestore
const testDartFunctionPubsubFirestoreV1 = 'admin-sdk-pubsub-firestore-v1';

/// Topic of [testDartFunctionPubsubFirestoreV1]
const testDartPubsubTopicFirestoreV1 = 'admin-sdk-topic-firestore-v1';

/// Firestore collection where [testDartFunctionPubsubFirestoreV1] records the
/// messages it receives.
const testPubsubFirestoreCollectionPath = 'tests_admin_sdk_pubsub';
