import 'package:tekartik_firebase/firebase_admin.dart';
import 'package:tekartik_firebase_auth/auth.dart';
import 'package:tekartik_firebase_firestore/firestore.dart';
import 'package:tekartik_firebase_storage/storage.dart';

/// Auth service for admin sdk.
abstract class FirebaseAuthServiceAdminSdk implements FirebaseAuthService {}

/// Firestore service for admin sdk.
abstract class FirebaseFirestoreServiceAdminSdk implements FirestoreService {}

/// Storage service for admin sdk.
abstract class FirebaseStorageServiceAdminSdk
    implements FirebaseStorageService {}

/// Options used when enqueuing a task, see [FirebaseTaskQueueAdminSdk.enqueue].
class FirebaseTaskEnqueueOptions {
  /// The id to use for the enqueued task, allowing de-duplication.
  ///
  /// When `null` one is generated. It can only contain letters (`[A-Za-z]`),
  /// numbers (`[0-9]`), hyphens (`-`), or underscores (`_`).
  final String? id;

  /// The delay before the task is attempted, relative to now.
  ///
  /// Mutually exclusive with [scheduleTime].
  final Duration? scheduleDelay;

  /// The absolute time at which the task should be attempted.
  ///
  /// Mutually exclusive with [scheduleDelay].
  final DateTime? scheduleTime;

  /// The deadline for the request sent to the function, in seconds.
  ///
  /// Must be in the range of 15 seconds to 30 minutes (1800 seconds).
  final int? dispatchDeadlineSeconds;

  /// Extra http headers to send along the task request.
  final Map<String, String>? headers;

  /// The full url the task request is sent to.
  ///
  /// When `null`, the deployed function url is used. This is needed when
  /// running against the Cloud Tasks emulator, which cannot resolve the
  /// production function url.
  final String? uri;

  /// Creates the options to enqueue a task, every parameter is optional.
  const FirebaseTaskEnqueueOptions({
    this.id,
    this.scheduleDelay,
    this.scheduleTime,
    this.dispatchDeadlineSeconds,
    this.headers,
    this.uri,
  });
}

/// A reference to the Cloud Tasks queue of a task dispatched function.
abstract class FirebaseTaskQueueAdminSdk {
  /// Enqueues a task with the given [data] payload.
  ///
  /// [data] is json encoded and delivered to the task dispatched function as
  /// its request data.
  Future<void> enqueue(
    Map<String, Object?> data, {
    FirebaseTaskEnqueueOptions? options,
  });

  /// Deletes the not yet executed task [id] from the queue.
  ///
  /// Does nothing if the task does not exist.
  Future<void> delete(String id);
}

/// Options used when publishing a message, see
/// [FirebasePubsubTopicAdminSdk.publish].
class FirebasePubsubPublishOptions {
  /// Attributes for this message (key-value pairs).
  final Map<String, String>? attributes;

  /// Ordering key for this message.
  final String? orderingKey;

  /// Creates the options to publish a message, every parameter is optional.
  const FirebasePubsubPublishOptions({this.attributes, this.orderingKey});
}

/// A reference to a Pub/Sub topic.
abstract class FirebasePubsubTopicAdminSdk {
  /// The topic name (its short name, not the full resource name).
  String get name;

  /// Creates the topic, does nothing if it already exists.
  Future<void> createIfNeeded();

  /// Publishes [data], json encoded, and returns the message id.
  Future<String> publish(
    Map<String, Object?> data, {
    FirebasePubsubPublishOptions? options,
  });

  /// Publishes [text] and returns the message id.
  Future<String> publishText(
    String text, {
    FirebasePubsubPublishOptions? options,
  });

  /// Publishes [bytes] and returns the message id.
  Future<String> publishBytes(
    List<int> bytes, {
    FirebasePubsubPublishOptions? options,
  });
}

/// Pub/Sub (topics) service for admin sdk.
///
/// Used to publish messages handled by a pub/sub triggered cloud function.
abstract class FirebasePubsubServiceAdminSdk {
  /// The topic [topicName] of the app project.
  FirebasePubsubTopicAdminSdk topic(FirebaseApp app, String topicName);
}

/// Tasks (Cloud Tasks queues) service for admin sdk.
///
/// Used to enqueue tasks handled by a task dispatched cloud function.
abstract class FirebaseTasksServiceAdminSdk {
  /// The task queue of the function [functionName] deployed in [region].
  ///
  /// When [region] is null, the default location (`us-central1`) is used.
  FirebaseTaskQueueAdminSdk taskQueue(
    FirebaseApp app,
    String functionName, {
    String? region,
  });
}

/// AdminSdk extension (if any)
abstract class FirebaseAdminSdk implements Firebase, FirebaseAdmin {
  /// Initialize rest with a service account json map.
  Future<FirebaseApp> initializeAppWithServiceAccountMap(
    Map map, {

    /// Overiden options (storage bucket, database url, ...)
    FirebaseAppOptions? options,
  });
}

/// AdminSdk app extension (if any)
abstract class FirebaseAppAdminSdk implements FirebaseApp {}
