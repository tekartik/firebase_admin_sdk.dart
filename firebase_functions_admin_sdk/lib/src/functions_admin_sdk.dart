import 'dart:io' as io;

import 'package:firebase_functions/firebase_functions.dart' as fn;
import 'package:tekartik_common_utils/common_utils_import.dart';
import 'package:tekartik_firebase/firebase_mixin.dart';
import 'package:tekartik_firebase_admin_sdk/firebase_admin_sdk.dart';
import 'package:tekartik_firebase_admin_sdk/firebase_auth_admin_sdk.dart';
import 'package:tekartik_firebase_admin_sdk/mixin_admin_sdk.dart';
//import 'package:tekartik_firebase_auth/src/auth.dart';
import 'package:tekartik_firebase_functions/firebase_functions.dart';
import 'package:tekartik_firebase_functions_http/firebase_functions_http_mixin.dart';

/// Callback type for the Admin SDK function registration.
typedef TekartikFirebaseFunctionsFireUpRunner =
    FutureOr<void> Function(FirebaseFunctions functions);

/// Admin SDK specific HTTPS options.
typedef HttpOptionsAdminSdk = fn.HttpsOptions;

/// Admin SDK Firebase Functions service.
abstract class FirebaseFunctionsServiceAdminSdk
    implements FirebaseFunctionsService {
  /// Starts the Firebase Functions runtime.
  Future<void> fireUp(TekartikFirebaseFunctionsAdminSdkRunner runner);
}

/// Admin SDK Firebase Functions instance.
abstract class FirebaseFunctionsAdminSdk implements FirebaseFunctions {
  /// Task queue (`onTaskDispatched`) functions.
  TasksFunctionsAdminSdk get tasks;

  /// Pub/Sub (`onMessagePublished`) functions.
  @override
  PubsubFunctionsAdminSdk get pubsub;
}

/// Request handler
typedef FirebaseFunctionsAdminSdkRequestHandler =
    FutureOr<fn.Response> Function(
      FirebaseFunctions firebaseFunctions,
      fn.Request request,
    );

/// Call handler
typedef FirebaseFunctionsAdminSdkCallHandler<T extends Object> =
    Future<fn.CallableResult<T>> Function(
      FirebaseFunctions firebaseFunctions,
      fn.CallableRequest<Object?> request,
      fn.CallableResponse<T> response,
    );

/// Pub/Sub message published handler.
///
/// Handles a message published on a topic (see `onMessagePublished`).
typedef FirebaseFunctionsAdminSdkPubsubHandler =
    Future<void> Function(
      FirebaseFunctions firebaseFunctions,
      fn.CloudEvent<fn.PubsubMessage> event,
    );

/// Task dispatched handler.
///
/// Handles a task enqueued in a Cloud Tasks queue (see `onTaskDispatched`).
typedef FirebaseFunctionsAdminSdkTaskHandler =
    Future<void> Function(
      FirebaseFunctions firebaseFunctions,
      fn.TaskRequest<Object?> request,
    );

/// Extension on native implementation
extension FirebaseFunctionsAdminSdkFirebaseExt on fn.Firebase {
  /// The abstracted firebase app;
  FirebaseAppAdminSdk get firebaseApp =>
      firebaseFunctionsServiceAdminSdk._impl.firebaseFunctionsAdminSdkApp ??=
          firebaseAdminSdk.fromNativeApp(adminApp);

  /// Https handler.
  Future<fn.Response> Function(fn.Request request) httpsHandler(
    FirebaseFunctionsAdminSdkRequestHandler handler,
  ) {
    return (request) async {
      var ff = _FirebaseFunctionsAdminSdk(
        service: firebaseFunctionsServiceAdminSdk._impl,
        rawFunctions: this,
      );
      return await handler.call(ff, request);
    };
  }

  /// Call handler.
  Future<fn.CallableResult<T>> Function(
    fn.CallableRequest<Object?> request,
    fn.CallableResponse<T> response,
  )
  callHandler<T extends Object>(
    FirebaseFunctionsAdminSdkCallHandler<T> handler,
  ) {
    return (request, response) async {
      var ff = _FirebaseFunctionsAdminSdk(
        service: firebaseFunctionsServiceAdminSdk._impl,
        rawFunctions: this,
      );
      return await handler.call(ff, request, response);
    };
  }

  /// Pub/Sub message published handler.
  ///
  /// To use with the native `pubsub.onMessagePublished`:
  /// ```dart
  /// firebase.pubsub.onMessagePublished(
  ///   firebase.pubsubHandler(myPubsubHandler),
  ///   topic: 'my-topic',
  /// );
  /// ```
  Future<void> Function(fn.CloudEvent<fn.PubsubMessage> event) pubsubHandler(
    FirebaseFunctionsAdminSdkPubsubHandler handler,
  ) {
    return (event) async {
      var ff = _FirebaseFunctionsAdminSdk(
        service: firebaseFunctionsServiceAdminSdk._impl,
        rawFunctions: this,
      );
      await handler.call(ff, event);
    };
  }

  /// Task dispatched handler.
  ///
  /// To use with the native `tasks.onTaskDispatched`:
  /// ```dart
  /// firebase.tasks.onTaskDispatched(
  ///   firebase.taskHandler(myTaskHandler),
  ///   name: 'my-task',
  /// );
  /// ```
  Future<void> Function(fn.TaskRequest<Object?> request) taskHandler(
    FirebaseFunctionsAdminSdkTaskHandler handler,
  ) {
    return (request) async {
      var ff = _FirebaseFunctionsAdminSdk(
        service: firebaseFunctionsServiceAdminSdk._impl,
        rawFunctions: this,
      );
      await handler.call(ff, request);
    };
  }
}

/// Admin SDK Https functions.
abstract class HttpsFunctionsAdminSdk implements HttpsFunctions {}

/// Callback type for the Admin SDK function registration.
typedef TekartikFirebaseFunctionsAdminSdkRunner =
    FutureOr<void> Function(FirebaseFunctionsAdminSdk functions);

class _FirebaseFunctionsServiceAdminSdk
    with
        FirebaseProductServiceMixin<FirebaseFunctions>,
        FirebaseFunctionsServiceDefaultMixin
    implements FirebaseFunctionsServiceAdminSdk {
  /// Global initialized once
  FirebaseAppAdminSdk? firebaseFunctionsAdminSdkApp;
  @override
  FirebaseFunctionsAdminSdk functions(FirebaseApp app) {
    throw UnimplementedError(
      'Use fireUp() for Admin SDK functions registration',
    );
  }

  @override
  Future<void> fireUp(TekartikFirebaseFunctionsAdminSdkRunner runner) async {
    await fn.runFunctions((rawFunctions) {
      var ff = _FirebaseFunctionsAdminSdk(
        service: this,
        rawFunctions: rawFunctions,
      );
      return runner.call(ff);
    });
  }
}

class _CallContextDecodedIdToken implements DecodedIdToken {
  @override
  final String uid;

  _CallContextDecodedIdToken({required this.uid});
}

class _CallContextAuthAdminSdk implements CallContextAuth {
  @override
  final _CallContextDecodedIdToken? token;

  _CallContextAuthAdminSdk({required this.token});

  @override
  String? get uid => token?.uid;
}

class _CallContextAdminSdk implements CallContext {
  @override
  final _CallContextAuthAdminSdk? auth;

  _CallContextAdminSdk({required this.auth});
}

class _CallRequestAdminSdk implements CallRequest {
  final fn.CallableRequest<Object?> request;
  final fn.CallableResponse<Object?> response;

  _CallRequestAdminSdk(this.request, this.response);
  @override
  late final context = () {
    var uid = request.instanceIdToken;
    _CallContextAuthAdminSdk? auth;
    if (uid != null) {
      auth = _CallContextAuthAdminSdk(
        token: _CallContextDecodedIdToken(uid: uid),
      );
    }
    var context = _CallContextAdminSdk(auth: auth);
    return context;
  }();

  @override
  Object? get data => request.data;

  @override
  // TODO: implement text
  String? get text {
    var data = this.data;
    if (data == null) {
      return null;
    }

    return jsonEncode(data);
  }
}

extension on FirebaseFunctionsAdminSdk {
  // ignore: unused_element
  _FirebaseFunctionsAdminSdk get _impl => this as _FirebaseFunctionsAdminSdk;
}

final bool _isEmulator = io.Platform.environment['FIREBASE_EMULATOR'] == 'true';

/// Public extension
extension FirebaseFunctionsAdminSdkExt on FirebaseFunctionsAdminSdk {
  /// True if running on emulator
  bool get isEmulator => _isEmulator;
}

/// Public extension
extension FirebaseFunctionsOnAdminSdkExt on FirebaseFunctions {
  /// True if running on emulator
  bool get isAdminSdkEmulator => _isEmulator;
}

extension on FirebaseFunctionsServiceAdminSdk {
  _FirebaseFunctionsServiceAdminSdk get _impl =>
      this as _FirebaseFunctionsServiceAdminSdk;
}

class _FirebaseFunctionsAdminSdk
    with
        FirebaseAppProductMixin<FirebaseFunctions>,
        FirebaseFunctionsDefaultMixin
    implements FirebaseFunctionsAdminSdk {
  /// The underlying raw functions instance.
  final fn.Firebase rawFunctions;

  @override
  final _FirebaseFunctionsServiceAdminSdk service;

  _FirebaseFunctionsAdminSdk({
    required this.service,
    required this.rawFunctions,
  });

  @override
  FirebaseApp get app => rawFunctions.firebaseApp;

  @override
  late final HttpsFunctionsAdminSdk https = _HttpsAdminSdk(this);

  @override
  late final SchedulerFunctionsAdminSdk scheduler = _SchedulerAdminSdk(this);

  @override
  late final TasksFunctionsAdminSdk tasks = _TasksAdminSdk(this);

  @override
  late final PubsubFunctionsAdminSdk pubsub = _PubsubAdminSdk(this);

  /// register a function
  @override
  void operator []=(String key, FirebaseFunction function) {
    // ignore: non_const_argument_for_const_parameter
    registerFunction(key, function);
  }

  @override
  void registerFunction(String name, FirebaseFunction function) {
    (function as FirebaseFunctionAdminSdk).register(name);
  }

  @override
  late final params = _ParamsAdminSdk(
    projectId: rawFunctions.adminApp.projectId!,
  );

  FirebaseFunctionsAdminSdkHttpsNamespace get httpsAdminSdk =>
      rawFunctions.https;
}

class _ParamsAdminSdk implements Params {
  @override
  final String projectId;

  _ParamsAdminSdk({required this.projectId});
}

class _HttpsAdminSdk
    with HttpsFunctionsDefaultMixin
    implements HttpsFunctionsAdminSdk {
  final _FirebaseFunctionsAdminSdk _functions;

  _HttpsAdminSdk(this._functions);

  @override
  HttpsCallableFunction onCall(
    CallHandler handler, {
    HttpsCallableOptions? callableOptions,
  }) {
    return _HttpsCallableFunctionAdminSdk(
      httpsAdminSdk: this,
      handler: handler,
      callableOptions: callableOptions,
    );
  }

  @override
  HttpsFunction onRequest(
    RequestHandler handler, {
    HttpsOptions? httpsOptions,
  }) {
    return _HttpsFunctionAdminSdk(
      httpsAdminSdk: this,
      handler: handler,
      httpsOptions: httpsOptions,
      fnHttpsOptions: null,
    );
  }
}

/// Admin SDK Https function.
abstract class HttpsFunctionAdminSdk
    implements FirebaseFunctionAdminSdk, HttpsFunction {}

/// Admin SDK Https callable function.
abstract class HttpsCallableFunctionAdminSdk
    implements FirebaseFunctionAdminSdk, HttpsCallableFunction {}

/// The cloud event type of a pub/sub message published event.
const pubsubMessagePublishedEventType =
    'google.cloud.pubsub.topic.v1.messagePublished';

/// Builds the cloud event json body delivered to a pub/sub triggered function.
///
/// [data] is the raw (base64 encoded) message data. Used to simulate a
/// message publication, the real one being done by Pub/Sub itself.
Map<String, Object?> pubsubMessagePublishedCloudEventJson({
  required String projectId,
  required String topic,
  required String data,
  Map<String, String>? attributes,
  String? orderingKey,
  String? messageId,
  String? eventId,
  DateTime? publishTime,
}) {
  var time = (publishTime ?? DateTime.now().toUtc()).toIso8601String();
  messageId ??= '1';
  return {
    'specversion': '1.0',
    'id': eventId ?? messageId,
    'source': '//pubsub.googleapis.com/projects/$projectId/topics/$topic',
    'type': pubsubMessagePublishedEventType,
    'time': time,
    'data': {
      'message': {
        'data': data,
        'attributes': attributes ?? <String, String>{},
        'messageId': messageId,
        'publishTime': time,
        'orderingKey': ?orderingKey,
      },
      'subscription': 'projects/$projectId/subscriptions/emulator-sub-$topic',
    },
  };
}

/// Admin SDK Pub/Sub functions, i.e. functions triggered by a message
/// published on a topic.
abstract class PubsubFunctionsAdminSdk implements PubsubFunctions {
  /// Registers a message published handler on [topic].
  ///
  /// The resulting function must be registered on the functions instance:
  /// ```dart
  /// functions['my-fn'] = functions.pubsub.onMessagePublished(
  ///   myPubsubHandler,
  ///   topic: 'my-topic',
  /// );
  /// ```
  PubsubFunctionAdminSdk onMessagePublished(
    FirebaseFunctionsAdminSdkPubsubHandler handler, {
    required String topic,
    FirebaseFunctionsAdminSdkPubsubOptions? options,
  });
}

/// Default mixin for [PubsubFunctionsAdminSdk] implementations, every member
/// throws an [UnimplementedError] unless overridden.
mixin PubsubFunctionsAdminSdkDefaultMixin implements PubsubFunctionsAdminSdk {
  @override
  PubsubFunctionAdminSdk onMessagePublished(
    FirebaseFunctionsAdminSdkPubsubHandler handler, {
    required String topic,
    FirebaseFunctionsAdminSdkPubsubOptions? options,
  }) {
    throw UnimplementedError('PubsubFunctionsAdminSdk.onMessagePublished');
  }

  @Deprecated('Use scheduler from firebase functions')
  @override
  ScheduleBuilder schedule(String expression) =>
      throw UnimplementedError('PubsubFunctions.schedule');
}

/// Admin SDK pub/sub message published function.
abstract class PubsubFunctionAdminSdk
    implements FirebaseFunctionAdminSdk, PubsubFunction {}

class _PubsubAdminSdk
    with PubsubFunctionsAdminSdkDefaultMixin
    implements PubsubFunctionsAdminSdk {
  final _FirebaseFunctionsAdminSdk _functions;

  _PubsubAdminSdk(this._functions);

  @override
  PubsubFunctionAdminSdk onMessagePublished(
    FirebaseFunctionsAdminSdkPubsubHandler handler, {
    required String topic,
    FirebaseFunctionsAdminSdkPubsubOptions? options,
  }) {
    return _PubsubFunctionAdminSdk(
      pubsubAdminSdk: this,
      handler: handler,
      topic: topic,
      options: options,
    );
  }
}

class _PubsubFunctionAdminSdk implements PubsubFunctionAdminSdk {
  final _PubsubAdminSdk pubsubAdminSdk;
  final FirebaseFunctionsAdminSdkPubsubHandler handler;
  final String topic;
  final FirebaseFunctionsAdminSdkPubsubOptions? options;

  _PubsubFunctionAdminSdk({
    required this.pubsubAdminSdk,
    required this.handler,
    required this.topic,
    required this.options,
  });

  @override
  void register(String name) {
    // The underlying Admin SDK derives the deployed function name from the
    // topic itself, so [name] is only used to key the function in the local
    // registry and has no effect on the deployed name.
    var functions = pubsubAdminSdk._functions;
    // ignore: experimental_member_use
    functions.rawFunctions.pubsub.onMessagePublished(
      (event) async => await handler(functions, event),
      // ignore: non_const_argument_for_const_parameter
      topic: topic,
      // ignore: non_const_argument_for_const_parameter
      options: options ?? const fn.PubSubOptions(),
    );
  }
}

/// The status code (no content) returned by a task dispatched function.
const taskDispatchedNoContentStatusCode = 204;

/// Cloud Tasks header holding the name of the queue.
const cloudTasksHeaderQueueName = 'X-CloudTasks-QueueName';

/// Cloud Tasks header holding the "short" name of the task.
const cloudTasksHeaderTaskName = 'X-CloudTasks-TaskName';

/// Cloud Tasks header holding the number of times the task has been retried.
const cloudTasksHeaderTaskRetryCount = 'X-CloudTasks-TaskRetryCount';

/// Cloud Tasks header holding the number of times the task has been executed.
const cloudTasksHeaderTaskExecutionCount = 'X-CloudTasks-TaskExecutionCount';

/// Cloud Tasks header holding the schedule time of the task.
const cloudTasksHeaderTaskEta = 'X-CloudTasks-TaskETA';

/// Cloud Tasks header holding the response code of the previous retry.
const cloudTasksHeaderTaskPreviousResponse =
    'X-CloudTasks-TaskPreviousResponse';

/// Cloud Tasks header holding the reason for retrying the task.
const cloudTasksHeaderTaskRetryReason = 'X-CloudTasks-TaskRetryReason';

/// Admin SDK Tasks functions, i.e. functions triggered by a task enqueued in
/// a Cloud Tasks queue.
abstract class TasksFunctionsAdminSdk {
  /// Registers a task dispatched handler.
  ///
  /// The resulting function must be registered on the functions instance to
  /// get its name (the queue name):
  /// ```dart
  /// functions['my-task'] = functions.tasks.onTaskDispatched(myTaskHandler);
  /// ```
  TaskFunctionAdminSdk onTaskDispatched(
    FirebaseFunctionsAdminSdkTaskHandler handler, {
    FirebaseFunctionsAdminSdkTaskQueueOptions? options,
  });
}

/// Default mixin for [TasksFunctionsAdminSdk] implementations, every member
/// throws an [UnimplementedError] unless overridden.
mixin TasksFunctionsAdminSdkDefaultMixin implements TasksFunctionsAdminSdk {
  @override
  TaskFunctionAdminSdk onTaskDispatched(
    FirebaseFunctionsAdminSdkTaskHandler handler, {
    FirebaseFunctionsAdminSdkTaskQueueOptions? options,
  }) {
    throw UnimplementedError('TasksFunctionsAdminSdk.onTaskDispatched');
  }
}

/// Admin SDK task dispatched function.
abstract class TaskFunctionAdminSdk implements FirebaseFunctionAdminSdk {}

class _TasksAdminSdk
    with TasksFunctionsAdminSdkDefaultMixin
    implements TasksFunctionsAdminSdk {
  final _FirebaseFunctionsAdminSdk _functions;

  _TasksAdminSdk(this._functions);

  @override
  TaskFunctionAdminSdk onTaskDispatched(
    FirebaseFunctionsAdminSdkTaskHandler handler, {
    FirebaseFunctionsAdminSdkTaskQueueOptions? options,
  }) {
    return _TaskFunctionAdminSdk(
      tasksAdminSdk: this,
      handler: handler,
      options: options,
    );
  }
}

class _TaskFunctionAdminSdk implements TaskFunctionAdminSdk {
  final _TasksAdminSdk tasksAdminSdk;
  final FirebaseFunctionsAdminSdkTaskHandler handler;
  final FirebaseFunctionsAdminSdkTaskQueueOptions? options;

  _TaskFunctionAdminSdk({
    required this.tasksAdminSdk,
    required this.handler,
    required this.options,
  });

  @override
  void register(String name) {
    var functions = tasksAdminSdk._functions;
    // ignore: experimental_member_use
    functions.rawFunctions.tasks.onTaskDispatched(
      (request) async => await handler(functions, request),
      // ignore: non_const_argument_for_const_parameter
      name: name,
      // ignore: non_const_argument_for_const_parameter
      options: options ?? const fn.TaskQueueOptions(),
    );
  }
}

/// Admin SDK Scheduler functions.
abstract class SchedulerFunctionsAdminSdk implements SchedulerFunctions {}

/// Admin SDK scheduled function.
abstract class ScheduleFunctionAdminSdk
    implements FirebaseFunctionAdminSdk, ScheduleFunction {}

class _SchedulerAdminSdk
    with SchedulerFunctionsDefaultMixin
    implements SchedulerFunctionsAdminSdk {
  final _FirebaseFunctionsAdminSdk _functions;

  _SchedulerAdminSdk(this._functions);

  @override
  ScheduleFunction onSchedule(
    ScheduleOptions scheduleOptions,
    ScheduleHandler handler,
  ) {
    return _ScheduleFunctionAdminSdk(
      schedulerAdminSdk: this,
      handler: handler,
      scheduleOptions: scheduleOptions,
    );
  }
}

class _ScheduleFunctionAdminSdk implements ScheduleFunctionAdminSdk {
  final _SchedulerAdminSdk schedulerAdminSdk;
  final ScheduleHandler handler;
  final ScheduleOptions scheduleOptions;

  _ScheduleFunctionAdminSdk({
    required this.schedulerAdminSdk,
    required this.handler,
    required this.scheduleOptions,
  });

  @override
  void register(String name) {
    // The underlying Admin SDK derives the deployed function name from the
    // schedule expression itself, so [name] is only used to key the function
    // in the local registry and has no effect on the deployed name.
    // ignore: experimental_member_use
    schedulerAdminSdk._functions.rawFunctions.scheduler.onSchedule(
      (event) async => await handler(_ScheduleEventAdminSdk(event)),
      // ignore: non_const_argument_for_const_parameter
      schedule: scheduleOptions.schedule,
      // ignore: non_const_argument_for_const_parameter
      options: _wrapScheduleOptions(scheduleOptions),
    );
  }

  fn.ScheduleOptions _wrapScheduleOptions(ScheduleOptions scheduleOptions) {
    var globalOptions = wrapGlobalOptions(scheduleOptions);
    return fn.ScheduleOptions(
      region: globalOptions.region,
      maxInstances: globalOptions.maxInstances,
      timeoutSeconds: globalOptions.timeoutSeconds,
      timeZone: scheduleOptions.timeZone == null
          ? null
          : fn.TimeZone(scheduleOptions.timeZone!),
    );
  }
}

class _ScheduleEventAdminSdk
    with SchedulerEventDefaultMixin
    implements ScheduleEvent {
  final fn.ScheduledEvent nativeEvent;

  _ScheduleEventAdminSdk(this.nativeEvent);

  @override
  String? get jobName => nativeEvent.jobName;

  @override
  String? get scheduleTime => nativeEvent.scheduleTime;
}

/// Firebase functions common
abstract class FirebaseFunctionAdminSdk implements FirebaseFunction {
  /// register
  void register(String name);
}

class _HttpsCallableFunctionAdminSdk implements HttpsCallableFunctionAdminSdk {
  final _HttpsAdminSdk httpsAdminSdk;
  final CallHandler handler;
  final HttpsCallableOptions? callableOptions;

  _HttpsCallableFunctionAdminSdk({
    required this.httpsAdminSdk,
    required this.handler,
    required this.callableOptions,
  });

  @override
  void register(String name) {
    httpsAdminSdk._functions.rawFunctions.https.onCall<Object>(
      (request, response) async {
        var callRequest = _CallRequestAdminSdk(request, response);
        var result = await handler.call(callRequest);
        return fn.CallableResult<Object>(result as Object);
      },
      // ignore: non_const_argument_for_const_parameter
      name: name,
      // ignore: non_const_argument_for_const_parameter
      options: _wrapCallableOptions(callableOptions),
    );
  }

  fn.CallableOptions? _wrapCallableOptions(
    HttpsCallableOptions? callableOptions,
  ) {
    if (callableOptions == null) {
      return null;
    }
    var globalOptions = wrapGlobalOptions(callableOptions);
    var fnCors = wrapCors(callableOptions.cors);
    return fn.CallableOptions(
      cors: fnCors,
      region: globalOptions.region,
      maxInstances: globalOptions.maxInstances,
      timeoutSeconds: globalOptions.timeoutSeconds,
    );
  }
}

class _HttpsFunctionAdminSdk implements HttpsFunctionAdminSdk {
  final _HttpsAdminSdk httpsAdminSdk;
  final RequestHandler handler;
  final FirebaseFunctionsAdminSdkHttpsOptions? fnHttpsOptions;
  final HttpsOptions? httpsOptions;

  _HttpsFunctionAdminSdk({
    required this.httpsAdminSdk,
    required this.handler,
    required this.httpsOptions,
    // ignore: experimental_member_use
    @mustBeConst required this.fnHttpsOptions,
  });

  @override
  void register(String name) {
    throw UnsupportedError(
      'user runFunctions with onRequest for Admin SDK functions registration',
    );
  }
}

/// Wrap the region as a string to a supported region
fn.Region? wrapRegion(String? region) {
  if (region == null) {
    return null;
  }
  var fnRegion = fn.Region(
    fn.SupportedRegion.values.firstWhere(
      (r) => r.value == region,
      orElse: () => throw ArgumentError('Unsupported region: $region'),
    ),
  );
  return fnRegion;
}

//fn.GlobalOptsion
/// Wrap instances
fn.Instances? wrapInstances(int? count) {
  if (count == null) {
    return null;
  }
  return fn.Instances(count);
}

/// Wrap global options
fn.GlobalOptions wrapGlobalOptions(GlobalOptions options) {
  var fnRegion = wrapRegion(options.region);
  var fnMaxInstances = wrapInstances(options.maxInstances);
  var fnTimeoutSeconds = wrapTimeoutSeconds(options.timeoutSeconds);
  return fn.GlobalOptions(
    region: fnRegion,
    maxInstances: fnMaxInstances,
    timeoutSeconds: fnTimeoutSeconds,
  );
}

/// Wrap cors
fn.Cors? wrapCors(bool? cors) {
  if (cors == null) {
    return null;
  }
  if (cors) {
    return const fn.Cors(['*']);
  }
  return null;
}

/// Wrap timeout
fn.TimeoutSeconds? wrapTimeoutSeconds(int? seconds) {
  if (seconds == null) {
    return null;
  }
  return fn.TimeoutSeconds(seconds);
}

/// Global Admin SDK functions service.
final FirebaseFunctionsServiceAdminSdk firebaseFunctionsServiceAdminSdk =
    _firebaseFunctionsServiceAdminSdk;

final _firebaseFunctionsServiceAdminSdk = _FirebaseFunctionsServiceAdminSdk();

/// Native Https options
typedef FirebaseFunctionsAdminSdkHttpsOptions = fn.HttpsOptions;

/// Native Region
typedef FirebaseFunctionsAdminSdkRegion = fn.Region;

/// Native SupportedRegion
typedef FirebaseFunctionsAdminSdkSupportedRegion = fn.SupportedRegion;

/// Native Cors
typedef FirebaseFunctionsAdminSdkCors = fn.Cors;

/// Native Instance
typedef FirebaseFunctionsAdminSdkInstances = fn.Instances;

/// Native https namespace
typedef FirebaseFunctionsAdminSdkHttpsNamespace = fn.HttpsNamespace;

/// Native tasks namespace
typedef FirebaseFunctionsAdminSdkTasksNamespace = fn.TasksNamespace;

/// Native pub/sub namespace
typedef FirebaseFunctionsAdminSdkPubsubNamespace = fn.PubSubNamespace;

/// Native pub/sub message
typedef FirebaseFunctionsAdminSdkPubsubMessage = fn.PubsubMessage;

/// Native cloud event
typedef FirebaseFunctionsAdminSdkCloudEvent<T> = fn.CloudEvent<T>;

/// Native pub/sub options
typedef FirebaseFunctionsAdminSdkPubsubOptions = fn.PubSubOptions;

/// Native task request
typedef FirebaseFunctionsAdminSdkTaskRequest<T> = fn.TaskRequest<T>;

/// Native task auth data
typedef FirebaseFunctionsAdminSdkTaskAuthData = fn.TaskAuthData;

/// Native task queue options
typedef FirebaseFunctionsAdminSdkTaskQueueOptions = fn.TaskQueueOptions;

/// Native task queue retry config
typedef FirebaseFunctionsAdminSdkTaskQueueRetryConfig = fn.TaskQueueRetryConfig;

/// Native task queue rate limits
typedef FirebaseFunctionsAdminSdkTaskQueueRateLimits = fn.TaskQueueRateLimits;

/// Native TimeoutSeconds
typedef FirebaseFunctionsAdminSdkTimeoutSeconds = fn.TimeoutSeconds;

/// Native response
typedef FirebaseFunctionsAdminSdkResponse = fn.Response;
