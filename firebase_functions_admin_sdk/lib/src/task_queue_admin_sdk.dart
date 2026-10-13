import 'package:firebase_functions/firebase_functions.dart' as fn;
import 'package:tekartik_firebase_admin_sdk/firebase_tasks_admin_sdk.dart';
import 'package:tekartik_firebase_functions/firebase_functions_tasks.dart';

/// The [TaskQueueService] of [app] (admin sdk, i.e. Cloud Tasks): enqueue
/// tasks to the task queue functions of the project.
///
/// [defaultRegion] is the region of the functions when [TaskQueueService.taskQueue]
/// gives none (the admin sdk defaults to `us-central1`).
TaskQueueService taskQueueServiceAdminSdk(
  FirebaseApp app, {
  String? defaultRegion,
}) => TaskQueueServiceAdminSdk(app, defaultRegion: defaultRegion);

/// The [TaskQueueService] of a firebase app on top of the admin sdk tasks
/// service (`firebaseTasksServiceAdminSdk`).
class TaskQueueServiceAdminSdk implements TaskQueueService {
  /// The firebase app (admin sdk).
  final FirebaseApp app;

  /// The region used when none is given.
  final String? defaultRegion;

  /// The admin sdk tasks service.
  final FirebaseTasksServiceAdminSdk tasksService;

  /// The [TaskQueueService] of [app]; [tasksService] defaults to
  /// `firebaseTasksServiceAdminSdk`.
  TaskQueueServiceAdminSdk(
    this.app, {
    this.defaultRegion,
    FirebaseTasksServiceAdminSdk? tasksService,
  }) : tasksService = tasksService ?? firebaseTasksServiceAdminSdk;

  @override
  TaskQueue taskQueue(String functionName, {String? region}) =>
      _TaskQueueAdminSdk(
        functionName,
        tasksService.taskQueue(
          app,
          functionName,
          region: region ?? defaultRegion,
        ),
      );
}

class _TaskQueueAdminSdk implements TaskQueue {
  @override
  final String functionName;
  final FirebaseTaskQueueAdminSdk queue;

  _TaskQueueAdminSdk(this.functionName, this.queue);

  @override
  Future<void> enqueue(
    Map<String, Object?> data, {
    TaskQueueEnqueueOptions? options,
  }) async {
    options?.validate();
    await queue.enqueue(
      data,
      options: options == null
          ? null
          : FirebaseTaskEnqueueOptions(
              id: options.id,
              scheduleDelay: options.scheduleDelay,
              scheduleTime: options.scheduleTime,
              uri: options.uri,
            ),
    );
  }
}

/// A native task request as a [TaskQueueRequest].
class TaskQueueRequestAdminSdk implements TaskQueueRequest {
  /// The native request.
  final fn.TaskRequest<Object?> nativeInstance;

  /// Wraps [nativeInstance].
  TaskQueueRequestAdminSdk(this.nativeInstance);

  @override
  Object? get data => nativeInstance.data;

  @override
  String get id => nativeInstance.id;

  @override
  String get queueName => nativeInstance.queueName;

  @override
  int get retryCount => nativeInstance.retryCount;

  @override
  int get executionCount => nativeInstance.executionCount;

  @override
  String toString() =>
      'TaskQueueRequestAdminSdk($queueName, $id, retry $retryCount)';
}

/// Task queue functions written against the tekartik abstraction, on the
/// native functions.
extension FirebaseFunctionsAdminSdkTaskQueueExt on fn.Firebase {
  /// A native task handler calling [handler] with a [TaskQueueRequest].
  ///
  /// To use with the native `tasks.onTaskDispatched` (name and options must
  /// be constants, `functions.yaml` is generated from them):
  /// ```dart
  /// firebase.tasks.onTaskDispatched(
  ///   firebase.taskQueueHandler(app.onTask),
  ///   name: 'mytaskv1',
  ///   options: const TaskQueueOptions(
  ///     region: Region(SupportedRegion.europeWest1),
  ///   ),
  /// );
  /// ```
  Future<void> Function(fn.TaskRequest<Object?> request) taskQueueHandler(
    TaskQueueHandler handler,
  ) =>
      (request) => handler(TaskQueueRequestAdminSdk(request));
}
