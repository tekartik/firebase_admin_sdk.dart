import 'dart:typed_data';

import 'package:cv/cv_json.dart';
import 'package:tekartik_common_utils/byte_utils.dart';
import 'package:tekartik_common_utils/common_utils_import.dart';
import 'package:tekartik_firebase_admin_sdk/firebase_tasks_admin_sdk.dart';
import 'package:tekartik_firebase_auth/auth.dart';
import 'package:tekartik_firebase_firestore/firestore.dart';
import 'package:tekartik_firebase_functions_admin_sdk/functions_admin_sdk.dart';

import 'package:tekartik_firebase_functions_admin_sdk_http/functions_admin_sdk_http.dart';
import 'package:tekartik_firebase_functions_admin_sdk_test/functions.dart';

import 'package:tekartik_http/http_client.dart';

export 'package:tekartik_firebase_functions_test/functions_basic.dart';
export 'src/constants.dart';
export 'src/functions_basic_admin_sdk.dart';
export 'src/task_record.dart';

/// Auth users command
/// Get the first 10 uids
const testApiCommandAuthUsers = 'auth/users';

/// Auth current user command
const testApiCommandAuthMe = 'auth/me';

/// Echo command
const testApiCommandEcho = 'echo';

/// Enqueue a task command.
///
/// Extra fields: `name` (the task function name), `region`, `uri` (the target
/// url, needed on the emulator) and `data` (the task payload).
const testApiCommandTasksEnqueue = 'tasks/enqueue';

/// List the tasks received so far command.
const testApiCommandTasksList = 'tasks/list';

/// Clear the tasks received so far command.
const testApiCommandTasksClear = 'tasks/clear';

/// List the tasks received so far in firestore command.
const testApiCommandTasksFirestoreList = 'tasks/firestore/list';

/// Clear the tasks received so far in firestore command.
const testApiCommandTasksFirestoreClear = 'tasks/firestore/clear';

/// Declares the HTTP runner for admin SDK test functions.
void declareRunner(FirebaseFunctionsAdminSdkHttp functions, {String? prefix}) {
  prefix ??= '';

  testFunctionsApiInitBuilders();
  functions.https.onAdminSdkRequest(
    '$prefix$testDartFunctionHttpsV1',
    functionsHttpV1Handler,
  );
  functions.https.onAdminSdkCall(
    '$prefix$testDartFunctionCallV1',
    functionsCallV1Handler,
  );
  functions.tasks.onAdminSdkTaskDispatched(
    '$prefix$testDartFunctionTaskV1',
    functionsTaskV1Handler,
  );
  functions.tasks.onAdminSdkTaskDispatched(
    '$prefix$testDartFunctionTaskFirestoreV1',
    functionsTaskFirestoreV1Handler,
  );
}

/// The information recorded for a received task.
Map<String, Object?> taskRequestToMap(TaskRequest<Object?> request) => {
  'data': ?request.data,
  'queueName': request.queueName,
  'id': request.id,
  'retryCount': request.retryCount,
  'executionCount': request.executionCount,
  'authUid': ?request.auth?.uid,
};

/// The firestore of the functions app.
///
/// It must have been initialized (`firestoreServiceAdminSdk.firestore(app)`)
/// when running on the admin sdk.
Firestore firebaseFunctionsFirestore(FirebaseFunctions firebaseFunctions) {
  var firestore = firebaseFunctions.app.getProduct<Firestore>();
  if (firestore == null) {
    throw StateError('No firestore registered on ${firebaseFunctions.app}');
  }
  return firestore;
}

/// Handler for the test task dispatched function recording in firestore.
///
/// Unlike [functionsTaskV1Handler], the received tasks are recorded in
/// firestore (in [testTasksFirestoreCollectionPath]), so that they can be
/// read even when the functions do not run on the test machine.
Future<void> functionsTaskFirestoreV1Handler(
  FirebaseFunctions firebaseFunctions,
  TaskRequest<Object?> request,
) async {
  var firestore = firebaseFunctionsFirestore(firebaseFunctions);
  await firestore
      .collection(testTasksFirestoreCollectionPath)
      .doc(request.id)
      .set(taskRequestToMap(request));
}

/// Handler for the test task dispatched function.
///
/// It records what it receives so that a test can check it (see
/// [testTaskRecordList]).
Future<void> functionsTaskV1Handler(
  FirebaseFunctions firebaseFunctions,
  TaskRequest<Object?> request,
) async {
  await testTaskRecordAdd(taskRequestToMap(request));
}

/// Handler for the test call function.
Future<CallableResult<Model>> functionsCallV1Handler(
  FirebaseFunctions firebaseFunctions,
  CallableRequest<Object?> request,
  CallableResponse<Model> response,
) async {
  var data = request.data;

  //print('headers: ${request.headers}')
  if (data is Map) {
    var apiRequest = data.cv<TestApiRequest>();
    var command = apiRequest.command.v;
    if (command != null) {
      switch (command) {
        case testApiCommandAuthUsers:
          var app = firebaseFunctions.app;

          var auth = app.getProduct<FirebaseAuth>()!;
          var listResult = await auth.listUsers(maxResults: 10);
          return CallableResult(
            asModel({
              'users': listResult.users
                  .map((record) => record?.uid)
                  .nonNulls
                  .toList(),
            }),
          );
        case testApiCommandAuthMe:
          var userId = request.auth?.uid;

          return CallableResult(asModel({'uid': userId}));
        case testApiCommandEcho:
          return CallableResult(Model.from({'data': data}));
        case testApiCommandTasksEnqueue:
          var name = data['name'] as String? ?? testDartFunctionTaskV1;
          var taskQueue = firebaseTasksServiceAdminSdk.taskQueue(
            firebaseFunctions.app,
            name,
            region: data['region'] as String?,
          );
          await taskQueue.enqueue(
            (data['data'] as Map?)?.cast<String, Object?>() ??
                <String, Object?>{},
            options: FirebaseTaskEnqueueOptions(uri: data['uri'] as String?),
          );
          return CallableResult(asModel({'enqueued': true}));
        case testApiCommandTasksList:
          return CallableResult(asModel({'tasks': await testTaskRecordList()}));
        case testApiCommandTasksClear:
          await testTaskRecordClear();
          return CallableResult(asModel({'cleared': true}));
        case testApiCommandTasksFirestoreList:
          var firestore = firebaseFunctionsFirestore(firebaseFunctions);
          var snapshot = await firestore
              .collection(testTasksFirestoreCollectionPath)
              .get();
          return CallableResult(
            asModel({'tasks': snapshot.docs.map((doc) => doc.data).toList()}),
          );
        case testApiCommandTasksFirestoreClear:
          var firestore = firebaseFunctionsFirestore(firebaseFunctions);
          var snapshot = await firestore
              .collection(testTasksFirestoreCollectionPath)
              .get();
          for (var doc in snapshot.docs) {
            await doc.ref.delete();
          }
          return CallableResult(asModel({'cleared': true}));
      }
    }
  }
  return CallableResult(
    Model.from({
      'data': ?data,
      'authUid': ?request.auth?.uid,
      'instanceIdToken': ?request.instanceIdToken,
    }),
  );
}

/// Handler for the test functions.
Future<Response> functionsHttpV1Handler(
  FirebaseFunctions firebaseFunctions,
  Request request,
) async {
  var info =
      parseBool(
        request.url.queryParameters['info'] ??
            request.requestedUri.queryParameters['info'],
      ) ??
      false;
  if (info) {
    String? body;
    Uint8List? bodyBytes;
    var contentLength = request.contentLength;
    var mimeType = request.mimeType;
    if ((contentLength ?? 0) > 0) {
      try {
        if (mimeType != null && mimeType != httpContentTypeBytes) {
          body = await request.readAsString();
        } else {
          bodyBytes = await listStreamGetBytes(request.read());
        }
      } catch (_) {}
    }

    return Response.ok(
      {
        'url': request.url.toString(),
        'requestedUri': request.requestedUri.toString(),
        'method': request.method,
        'body': ?body,
        'bodyBytes': ?bodyBytes,
        'mimeType': ?mimeType,
        'contentLength': contentLength ?? 0,
        'protocolVersion': request.protocolVersion,
      }.cvToJson(),
    );
  }
  //print(request.url);
  //print(request.requestedUri);
  return Response.ok('Hello');
}
