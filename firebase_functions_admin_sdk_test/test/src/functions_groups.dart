import 'package:tekartik_firebase_functions_admin_sdk_test/functions_test_runner.dart';
import 'package:tekartik_firebase_functions_admin_sdk_test/test_context.dart';
import 'package:test/test.dart';

/// All the function groups, run against [context].
void functionsAdminSdkGroups(FirebaseFunctionsAdminSdkTestContext context) {
  group('https', () => functionsHttpGroup(context));
  group('call', () => functionsCallGroup(context));
  group('tasks', () => functionsTaskGroup(context));
  group('tasks firestore', () => functionsTaskFirestoreGroup(context));
  group('pubsub', () => functionsPubsubGroup(context));
  group('pubsub firestore', () => functionsPubsubFirestoreGroup(context));
}
