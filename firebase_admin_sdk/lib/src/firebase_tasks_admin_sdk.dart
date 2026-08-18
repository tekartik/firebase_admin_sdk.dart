import 'package:firebase_admin_sdk/firebase_admin_sdk.dart' as admin_sdk;
import 'package:firebase_admin_sdk/functions.dart' as sdk;
import 'package:tekartik_firebase/firebase.dart';

import 'firebase_admin_sdk_common.dart';

/// The tasks (i.e. Cloud Tasks queues) service for admin sdk.
FirebaseTasksServiceAdminSdk get firebaseTasksServiceAdminSdk =>
    _tasksServiceAdminSdk ??= _FirebaseTasksServiceAdminSdk();

FirebaseTasksServiceAdminSdk? _tasksServiceAdminSdk;

class _FirebaseTasksServiceAdminSdk implements FirebaseTasksServiceAdminSdk {
  @override
  FirebaseTaskQueueAdminSdk taskQueue(
    FirebaseApp app,
    String functionName, {
    String? region,
  }) {
    assert(app is FirebaseAppAdminSdk, 'invalid firebase app type');
    var adminApp = app as FirebaseAppAdminSdk;
    var sdkApp = (adminApp as dynamic).nativeInstance as admin_sdk.FirebaseApp;
    var resourceName = region == null
        ? functionName
        : 'locations/$region/functions/$functionName';
    return _FirebaseTaskQueueAdminSdk(
      sdkApp.functions().taskQueue(resourceName),
    );
  }
}

class _FirebaseTaskQueueAdminSdk implements FirebaseTaskQueueAdminSdk {
  /// Native instance
  final sdk.TaskQueue nativeInstance;

  _FirebaseTaskQueueAdminSdk(this.nativeInstance);

  @override
  Future<void> enqueue(
    Map<String, Object?> data, {
    FirebaseTaskEnqueueOptions? options,
  }) async {
    await nativeInstance.enqueue(data, _wrapOptions(options));
  }

  @override
  Future<void> delete(String id) async {
    await nativeInstance.delete(id);
  }
}

sdk.TaskOptions? _wrapOptions(FirebaseTaskEnqueueOptions? options) {
  if (options == null) {
    return null;
  }
  var scheduleDelay = options.scheduleDelay;
  var scheduleTime = options.scheduleTime;
  if (scheduleDelay != null && scheduleTime != null) {
    throw ArgumentError('scheduleDelay and scheduleTime are exclusive');
  }
  var uri = options.uri;
  return sdk.TaskOptions(
    id: options.id,
    dispatchDeadlineSeconds: options.dispatchDeadlineSeconds,
    headers: options.headers,
    schedule: scheduleDelay != null
        ? sdk.DelayDelivery(scheduleDelay.inSeconds)
        : (scheduleTime != null ? sdk.AbsoluteDelivery(scheduleTime) : null),
    experimental: uri == null ? null : sdk.TaskOptionsExperimental(uri: uri),
  );
}
