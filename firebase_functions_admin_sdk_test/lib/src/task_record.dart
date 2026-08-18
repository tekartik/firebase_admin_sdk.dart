import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart';

/// The file where the test task dispatched function records the tasks it
/// received.
///
/// Functions run in a separate process when running on the emulator, so a
/// file on the local file system is used to share the received tasks between
/// the function and the test.
File get testTaskRecordFile => File(
  join(
    Directory.systemTemp.path,
    'tekartik_firebase_functions_admin_sdk_test',
    'received_tasks.json',
  ),
);

/// Clears the recorded tasks.
Future<void> testTaskRecordClear() async {
  var file = testTaskRecordFile;
  if (file.existsSync()) {
    await file.delete();
  }
}

/// The tasks recorded so far, oldest first.
Future<List<Map<String, Object?>>> testTaskRecordList() async {
  var file = testTaskRecordFile;
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

/// Records a received task.
Future<void> testTaskRecordAdd(Map<String, Object?> task) async {
  var file = testTaskRecordFile;
  await file.parent.create(recursive: true);
  var list = await testTaskRecordList()
    ..add(task);
  await file.writeAsString(jsonEncode(list));
}
