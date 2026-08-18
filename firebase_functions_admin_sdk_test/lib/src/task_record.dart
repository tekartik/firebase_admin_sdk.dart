import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart';

/// Record kind for the tasks received by the test task dispatched function.
const testRecordKindTask = 'task';

/// Record kind for the messages received by the test pub/sub function.
const testRecordKindPubsub = 'pubsub';

/// The file where a test function records what it receives.
///
/// Functions run in a separate process when running on the emulator, so a
/// file on the local file system is used to share the records between the
/// function and the test.
File testRecordFile(String kind) => File(
  join(
    Directory.systemTemp.path,
    'tekartik_firebase_functions_admin_sdk_test',
    'received_${kind}s.json',
  ),
);

/// Clears the records of [kind].
Future<void> testRecordClear(String kind) async {
  var file = testRecordFile(kind);
  if (file.existsSync()) {
    await file.delete();
  }
}

/// The records of [kind] so far, oldest first.
Future<List<Map<String, Object?>>> testRecordList(String kind) async {
  var file = testRecordFile(kind);
  if (!file.existsSync()) {
    return <Map<String, Object?>>[];
  }
  try {
    var list = jsonDecode(await file.readAsString()) as List;
    return list.map((item) => (item as Map).cast<String, Object?>()).toList();
  } catch (_) {
    /// Could happen if read while being written.
    return <Map<String, Object?>>[];
  }
}

/// Adds a record of [kind].
Future<void> testRecordAdd(String kind, Map<String, Object?> record) async {
  var file = testRecordFile(kind);
  await file.parent.create(recursive: true);
  var list = await testRecordList(kind)
    ..add(record);
  await file.writeAsString(jsonEncode(list));
}

/// The file where the test task dispatched function records the tasks it
/// received.
File get testTaskRecordFile => testRecordFile(testRecordKindTask);

/// Clears the recorded tasks.
Future<void> testTaskRecordClear() => testRecordClear(testRecordKindTask);

/// The tasks recorded so far, oldest first.
Future<List<Map<String, Object?>>> testTaskRecordList() =>
    testRecordList(testRecordKindTask);

/// Records a received task.
Future<void> testTaskRecordAdd(Map<String, Object?> task) =>
    testRecordAdd(testRecordKindTask, task);

/// The file where the test pub/sub function records the messages it received.
File get testPubsubRecordFile => testRecordFile(testRecordKindPubsub);

/// Clears the recorded pub/sub messages.
Future<void> testPubsubRecordClear() => testRecordClear(testRecordKindPubsub);

/// The pub/sub messages recorded so far, oldest first.
Future<List<Map<String, Object?>>> testPubsubRecordList() =>
    testRecordList(testRecordKindPubsub);

/// Records a received pub/sub message.
Future<void> testPubsubRecordAdd(Map<String, Object?> message) =>
    testRecordAdd(testRecordKindPubsub, message);
