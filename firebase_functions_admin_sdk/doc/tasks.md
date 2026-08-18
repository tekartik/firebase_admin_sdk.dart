# Task queue functions

A task queue function (`onTaskDispatched`) is triggered by a task enqueued in
a Cloud Tasks queue. The queue name is the function name.

## Handling a task

The handler is a `FirebaseFunctionsAdminSdkTaskHandler`:

```dart
Future<void> myTaskHandler(
  FirebaseFunctions firebaseFunctions,
  TaskRequest<Object?> request,
) async {
  print('data: ${request.data}, retryCount: ${request.retryCount}');
}
```

Deployed (or emulated) functions are declared in `bin/server.dart`, the
function name and its options must be constants so that the
`package:firebase_functions` builder can generate `functions.yaml`:

```dart
runFunctions((firebase) {
  // ignore: experimental_member_use
  firebase.tasks.onTaskDispatched(
    firebase.taskHandler(myTaskHandler),
    name: 'my-task',
    options: const TaskQueueOptions(
      region: Region(SupportedRegion.europeWest1),
      retryConfig: TaskQueueRetryConfig(maxAttempts: MaxAttempts(2)),
    ),
  );
});
```

Locally (`tekartik_firebase_functions_admin_sdk_http`), the same handler is
registered on the local http server, which simulates a Cloud Tasks delivery
(a `POST` with a `{'data': ...}` json body, answered with a `204`):

```dart
functions.tasks.onAdminSdkTaskDispatched('my-task', myTaskHandler);
```

## Enqueuing a task

Enqueuing uses the admin sdk (see `tekartik_firebase_admin_sdk`), from a
server or from another function:

```dart
var queue = firebaseTasksServiceAdminSdk.taskQueue(
  app,
  'my-task',
  region: regionBelgium,
);
await queue.enqueue({'my': 'data'});
```

### Emulator

The `tasks` emulator is started along with the `functions` emulator and the
`CLOUD_TASKS_EMULATOR_HOST` environment variable is set for the emulated
functions, so a function enqueuing a task targets the emulator.

The task url built by the admin sdk is always the production function url,
which the emulator cannot resolve, so it must be overridden with the emulated
function url:

```dart
await queue.enqueue(
  {'my': 'data'},
  options: FirebaseTaskEnqueueOptions(
    uri: 'http://localhost:5001/$projectId/$region/my-task',
  ),
);
```
