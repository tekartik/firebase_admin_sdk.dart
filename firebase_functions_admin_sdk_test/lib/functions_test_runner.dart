import 'package:cv/cv_json.dart';
import 'package:dev_test/dev_test.dart';
import 'package:path/path.dart';
import 'package:tekartik_firebase_functions_admin_sdk_test/test_context.dart';
import 'package:tekartik_http/http.dart';

import 'functions.dart';
import 'src/call_task.dart';

extension on Uri {
  Uri withInfo() => replace(queryParameters: {'info': 'true'});
}

/// Test group fpr functions Call
void functionsCallGroup(FirebaseFunctionsAdminSdkTestContext context) {
  late Client client;

  setUpAll(() async {
    await context.setUpAll();
    client = context.client;
  });

  test('hello', () async {
    var uri = context.httpsUri(testDartFunctionCallV1);
    var response = await httpClientSend(
      client,
      httpMethodPost,
      uri,
      headers: (HttpHeaders()..mimeType = httpContentTypeJson).toStringMap(),

      /// 'data' field required
      body: {
        'data': {'test': 'Hello'},
      }.cvToJson(),
    );
    var result = response.body;
    // print('response header: ${response.headers.cvToJsonPretty()}');
    // header: {
    //   "connection": "keep-alive",
    //   "x-powered-by": "Dart with package:shelf",
    //   "access-control-allow-headers": "*",
    //   "keep-alive": "timeout=5",
    //   "date": "Sun, 31 May 2026 14:40:54 GMT",
    //   "access-control-allow-origin": "*",
    //   "access-control-allow-methods": "*",
    //   "content-length": "36",
    //   "content-type": "application/json",
    //   "x-frame-options": "SAMEORIGIN",
    //   "x-xss-protection": "1; mode=block",
    //   "x-content-type-options": "nosniff"
    // }
    expect(response.statusCode, 200);

    var map = result.jsonToMap();
    // {
    //   "url": "admin-sdk-https-v1/?info=true",
    //   "requestedUri": "http://localhost:5001/admin-sdk-https-v1/?info=true",
    //   "method": "GET",
    //   "protocolVersion": "1.1"
    // }
    // ignore: avoid_print
    print(map.cvToJsonPretty());

    // result enclosed
    expect(map, {
      'result': {
        'data': {'test': 'Hello'},
      },
    });
  });

  test('auth/users', () async {
    var request = TestApiRequest()..command.v = testApiCommandAuthUsers;
    var uri = context.httpsUri(testDartFunctionCallV1);
    var map = (await httpClientRead(
      client,
      httpMethodPost,
      uri,
      headers: (HttpHeaders()..mimeType = httpContentTypeJson).toStringMap(),

      /// 'data' field required
      body: {'data': request.toMap()}.cvToJson(),
    )).jsonToMap();
    var result = map['result'] as Map;
    // ignore: avoid_print
    print('result: ${result.cvToJsonPretty()}');
  });
}

/// Test group for functions HTTP.
void functionsHttpGroup(FirebaseFunctionsAdminSdkTestContext context) {
  late Client client;

  setUpAll(() async {
    await context.setUpAll();
    client = context.client;
  });

  /// Most basic
  test('hello', () async {
    var uri = context.httpsUri(testDartFunctionHttpsV1);
    var result = await httpClientRead(client, httpMethodGet, uri);
    // ignore: avoid_print
    print('helloWorld: $result');

    expect(result, contains('Hello'));
    var response = await httpClientSend(client, httpMethodGet, uri);

    expect(response.statusCode, 200);
    // headers:
    // {
    //             'connection': 'keep-alive',
    //             'x-powered-by': 'Dart with package:shelf',
    //             'access-control-allow-headers': '*',
    //             'keep-alive': 'timeout=5',
    //             'date': 'Sat, 30 May 2026 10:10:36 GMT',
    //             'access-control-allow-origin': '*',
    //             'access-control-allow-methods': '*',
    //             'content-length': '5',
    //             'content-type': 'text/plain; charset=utf-8',
    //             'x-frame-options': 'SAMEORIGIN',
    //             'x-xss-protection': '1; mode=block',
    //             'x-content-type-options': 'nosniff'
    //           }
    expect(response.headers['content-length'], '5');
  });

  test('?info', () async {
    var uri = context.httpsUri(testDartFunctionHttpsV1).withInfo();
    var result = await httpClientRead(client, httpMethodGet, uri);
    var map = result.jsonToMap();
    // {
    //   "url": "admin-sdk-https-v1/?info=true",
    //   "requestedUri": "http://localhost:5001/admin-sdk-https-v1/?info=true",
    //   "method": "GET",
    //   "protocolVersion": "1.1"
    // }
    // ignore: avoid_print
    print(map.cvToJsonPretty());

    expect(map['requestedUri'], endsWith('/?info=true'));

    expect(map['url'], endsWith('?info=true')); // deployed has en empty url
    map
      ..remove('requestedUri')
      ..remove('url');
    expect(map, {
      'method': 'GET',
      'contentLength': 0,
      'protocolVersion': '1.1',
    });
    // ignore: dead_code
    if (false) {
      uri = context
          .httpsUri(url.join(testDartFunctionHttpsV1, 'sub'))
          .withInfo();
      result = await httpClientRead(client, httpMethodGet, uri);
      map = result.jsonToMap();
      // {
      //   "url": "admin-sdk-https-v1/?info=true",
      //   "requestedUri": "http://localhost:5001/admin-sdk-https-v1/?info=true",
      //   "method": "GET",
      //   "protocolVersion": "1.1"
      // }
      // ignore: avoid_print
      print(map.cvToJsonPretty());

      expect(map['requestedUri'], endsWith('/sub?info=true'));
      expect(
        map['url'],

        endsWith('sub?info=true'),
      ); // deployed has en empty url
    }
    result = await httpClientRead(client, httpMethodPost, uri, body: 'test');
    map = result.jsonToMap();

    // ignore: avoid_print
    print(map.cvToJsonPretty());

    expect(map['body'], 'test');

    expect(map['mimeType'], 'text/plain');

    expect(map['contentLength'], 4);

    result = await httpClientRead(
      client,
      httpMethodPost,
      uri,
      body: [0xC0, 0x80],
    );
    map = result.jsonToMap();
    // ignore: avoid_print
    print(map.cvToJsonPretty());

    expect(map['bodyBytes'], [0xC0, 0x80]);

    expect(map['mimeType'], isNull);

    expect(map['contentLength'], 2);

    result = await httpClientRead(
      client,
      httpMethodPost,
      uri,
      body: [0xC0, 0x80],
      headers: (HttpHeaders()..mimeType = httpContentTypeBytes).toStringMap(),
    );
    map = result.jsonToMap();
    // ignore: avoid_print
    print(map.cvToJsonPretty());

    expect(map['bodyBytes'], [0xC0, 0x80]);

    expect(map['mimeType'], httpContentTypeBytes);

    expect(map['contentLength'], 2);
  });
}

/// Waits for at least [count] tasks to be received by the test task function.
Future<List<Map<String, Object?>>> waitForReceivedTasks(
  int count, {
  Duration? timeout,
}) async {
  timeout ??= const Duration(seconds: 30);
  var stopwatch = Stopwatch()..start();
  while (true) {
    var list = await testTaskRecordList();
    if (list.length >= count) {
      return list;
    }
    if (stopwatch.elapsed > timeout) {
      throw StateError(
        'Timeout waiting for $count task(s), got ${list.length}',
      );
    }
    await Future<void>.delayed(const Duration(milliseconds: 200));
  }
}

/// Test group for task dispatched functions.
void functionsTaskGroup(FirebaseFunctionsAdminSdkTestContext context) {
  setUpAll(() async {
    await context.setUpAll();
  });

  test('task dispatched', () async {
    await testTaskRecordClear();
    var data = <String, Object?>{'test': 'task', 'value': 1};
    await context.enqueueTask(testDartFunctionTaskV1, data);

    var tasks = await waitForReceivedTasks(1);
    // ignore: avoid_print
    print('tasks: ${tasks.cvToJsonPretty()}');
    expect(tasks, hasLength(1));
    var task = tasks.first;
    expect(task['data'], data);

    /// The emulator sends its internal queue key
    /// (`queue:<project>-<region>-<name>`), the local http server sends the
    /// function name.
    expect(task['queueName'], contains(testDartFunctionTaskV1));
    expect(task['id'], isNotNull);
    expect(task['retryCount'], 0);
    expect(task['executionCount'], 0);
  });
}

/// Waits for at least [count] tasks to be recorded in firestore.
Future<List<Map<String, Object?>>> waitForFirestoreTasks(
  FirebaseFunctionsAdminSdkTestContext context,
  int count, {
  Duration? timeout,
}) async {
  timeout ??= const Duration(seconds: 30);
  var stopwatch = Stopwatch()..start();
  while (true) {
    var list = await callFunctionTasksFirestoreList(context);
    if (list.length >= count) {
      return list;
    }
    if (stopwatch.elapsed > timeout) {
      throw StateError(
        'Timeout waiting for $count firestore task(s), got ${list.length}',
      );
    }
    await Future<void>.delayed(const Duration(milliseconds: 200));
  }
}

/// Test group for task dispatched functions recording in firestore.
///
/// Same as [functionsTaskGroup] but the received tasks are recorded in
/// firestore (and read back through the test call function) instead of a
/// local file, so it also works when the functions do not run on the test
/// machine.
///
/// A firestore must be registered on the functions app (in the emulator,
/// the firestore emulator must be started too).
void functionsTaskFirestoreGroup(FirebaseFunctionsAdminSdkTestContext context) {
  setUpAll(() async {
    await context.setUpAll();
  });

  test('task dispatched firestore', () async {
    await callFunctionTasksFirestoreClear(context);
    var data = <String, Object?>{'test': 'firestore task', 'value': 2};
    await context.enqueueTask(testDartFunctionTaskFirestoreV1, data);

    var tasks = await waitForFirestoreTasks(context, 1);
    // ignore: avoid_print
    print('firestore tasks: ${tasks.cvToJsonPretty()}');
    expect(tasks, hasLength(1));
    var task = tasks.first;
    expect(task['data'], data);
    expect(task['queueName'], contains(testDartFunctionTaskFirestoreV1));
    expect(task['id'], isNotNull);
    expect(task['retryCount'], 0);
    expect(task['executionCount'], 0);
  });
}

/// Waits for at least [count] pub/sub messages to be received by the test
/// pub/sub function.
Future<List<Map<String, Object?>>> waitForReceivedMessages(
  int count, {
  Duration? timeout,
}) async {
  timeout ??= const Duration(seconds: 30);
  var stopwatch = Stopwatch()..start();
  while (true) {
    var list = await testPubsubRecordList();
    if (list.length >= count) {
      return list;
    }
    if (stopwatch.elapsed > timeout) {
      throw StateError(
        'Timeout waiting for $count message(s), got ${list.length}',
      );
    }
    await Future<void>.delayed(const Duration(milliseconds: 200));
  }
}

/// Test group for pub/sub triggered functions.
void functionsPubsubGroup(FirebaseFunctionsAdminSdkTestContext context) {
  setUpAll(() async {
    await context.setUpAll();
  });

  test('message published', () async {
    await testPubsubRecordClear();
    var data = <String, Object?>{'test': 'message', 'value': 1};
    await context.publishMessage(testDartPubsubTopicV1, data);

    var messages = await waitForReceivedMessages(1);
    // ignore: avoid_print
    print('messages: ${messages.cvToJsonPretty()}');
    expect(messages, hasLength(1));
    var message = messages.first;
    expect(message['data'], data);
    expect(message['messageId'], isNotNull);
    expect(message['source'], contains(testDartPubsubTopicV1));
  });
}

/// Waits for at least [count] pub/sub messages to be recorded in firestore.
Future<List<Map<String, Object?>>> waitForFirestoreMessages(
  FirebaseFunctionsAdminSdkTestContext context,
  int count, {
  Duration? timeout,
}) async {
  timeout ??= const Duration(seconds: 30);
  var stopwatch = Stopwatch()..start();
  while (true) {
    var list = await callFunctionPubsubFirestoreList(context);
    if (list.length >= count) {
      return list;
    }
    if (stopwatch.elapsed > timeout) {
      throw StateError(
        'Timeout waiting for $count firestore message(s), got ${list.length}',
      );
    }
    await Future<void>.delayed(const Duration(milliseconds: 200));
  }
}

/// Test group for pub/sub triggered functions recording in firestore.
///
/// Same as [functionsPubsubGroup] but the received messages are recorded in
/// firestore (and read back through the test call function) instead of a
/// local file, so it also works when the functions do not run on the test
/// machine.
///
/// A firestore must be registered on the functions app (in the emulator, the
/// firestore emulator must be started too).
void functionsPubsubFirestoreGroup(
  FirebaseFunctionsAdminSdkTestContext context,
) {
  setUpAll(() async {
    await context.setUpAll();
  });

  test('message published firestore', () async {
    await callFunctionPubsubFirestoreClear(context);
    var data = <String, Object?>{'test': 'firestore message', 'value': 2};
    await context.publishMessage(testDartPubsubTopicFirestoreV1, data);

    var messages = await waitForFirestoreMessages(context, 1);
    // ignore: avoid_print
    print('firestore messages: ${messages.cvToJsonPretty()}');
    expect(messages, hasLength(1));
    var message = messages.first;
    expect(message['data'], data);
    expect(message['messageId'], isNotNull);
    expect(message['source'], contains(testDartPubsubTopicFirestoreV1));
  });
}
