@TestOn('vm')
library;

import 'package:firebase_functions/firebase_functions.dart' as fn;
import 'package:shelf/shelf.dart' as shelf;
import 'package:tekartik_firebase_admin_sdk/firebase_tasks_admin_sdk.dart';
import 'package:tekartik_firebase_functions/firebase_functions_tasks.dart';
import 'package:tekartik_firebase_functions_admin_sdk/functions_admin_sdk.dart';
import 'package:test/test.dart';

class _QueueMock implements FirebaseTaskQueueAdminSdk {
  final enqueued = <(Map<String, Object?>, FirebaseTaskEnqueueOptions?)>[];
  @override
  Future<void> delete(String id) async {}

  @override
  Future<void> enqueue(
    Map<String, Object?> data, {
    FirebaseTaskEnqueueOptions? options,
  }) async {
    enqueued.add((data, options));
  }
}

class _TasksServiceMock implements FirebaseTasksServiceAdminSdk {
  final queues = <String, _QueueMock>{};
  final regions = <String?>[];
  @override
  FirebaseTaskQueueAdminSdk taskQueue(
    FirebaseApp app,
    String functionName, {
    String? region,
  }) {
    regions.add(region);
    return queues[functionName] ??= _QueueMock();
  }
}

class _AppMock implements FirebaseApp {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('TaskQueueRequestAdminSdk', () async {
    var native = fn.TaskRequest<Object?>(
      shelf.Request('POST', Uri.parse('http://localhost/mytask')),
      {'value': 1},
      queueName: 'mytask',
      id: 'task1',
      retryCount: 2,
      executionCount: 3,
      scheduledTime: '2026-10-13T00:00:00Z',
    );
    // What `firebase.taskQueueHandler(handler)` hands to the handler.
    TaskQueueRequest received = TaskQueueRequestAdminSdk(native);
    expect(received.data, {'value': 1});
    expect(received.id, 'task1');
    expect(received.queueName, 'mytask');
    expect(received.retryCount, 2);
    expect(received.executionCount, 3);
  });

  test('TaskQueueServiceAdminSdk', () async {
    var tasksService = _TasksServiceMock();
    var service = TaskQueueServiceAdminSdk(
      _AppMock(),
      defaultRegion: 'europe-west1',
      tasksService: tasksService,
    );
    var queue = service.taskQueue('mytask');
    expect(queue.functionName, 'mytask');
    await queue.enqueue({'a': 1});
    await queue.enqueue(
      {'b': 2},
      options: const TaskQueueEnqueueOptions(
        id: 'id1',
        scheduleDelay: Duration(seconds: 5),
        uri: 'http://localhost:5001/p/r/mytask',
      ),
    );
    service.taskQueue('mytask', region: 'us-central1');
    expect(tasksService.regions, ['europe-west1', 'us-central1']);
    var enqueued = tasksService.queues['mytask']!.enqueued;
    expect(enqueued[0].$1, {'a': 1});
    expect(enqueued[0].$2, isNull);
    expect(enqueued[1].$1, {'b': 2});
    var options = enqueued[1].$2!;
    expect(options.id, 'id1');
    expect(options.scheduleDelay, const Duration(seconds: 5));
    expect(options.uri, 'http://localhost:5001/p/r/mytask');
  });
}
