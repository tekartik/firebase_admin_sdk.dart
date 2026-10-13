import 'package:tekartik_firebase_auth_local/auth_local.dart';
import 'package:tekartik_firebase_firestore_sembast/firestore_sembast.dart';
import 'package:tekartik_firebase_functions_admin_sdk_test/functions.dart';
import 'package:tekartik_firebase_functions_admin_sdk_test/http_test_context.dart';
import 'package:tekartik_firebase_local/firebase_local.dart';
import 'package:tekartik_http/http_memory.dart';
import 'package:test/test.dart';

import 'src/functions_groups.dart';

Future main() async {
  var app = newFirebaseAppMemory();
  newAuthServiceLocal().auth(app);
  newFirestoreServiceMemory().firestore(app);
  var httpFactory = httpFactoryMemory;

  var testContext = _CountingHttpTestContext(
    app: app,
    declarer: declareRunner,
    httpFactory: httpFactory,
  );
  group('firebase_functions_dart', () {
    setUpAll(() async {
      await testContext.setUpAll();
    });
    tearDownAll(() async {
      await testContext.tearDownAll();
    });
    functionsAdminSdkGroups(testContext);
  });
  tearDownAll(() {
    // Every setUpAll of the groups has its tearDownAll (the context is
    // released, the client closed).
    expect(testContext.tearDowns, testContext.setUps);
  });
}

/// Counts the context setups and teardowns.
class _CountingHttpTestContext
    extends FirebaseFunctionsAdminSdkHttpTestContext {
  var setUps = 0;
  var tearDowns = 0;

  _CountingHttpTestContext({
    required super.app,
    required super.declarer,
    super.httpFactory,
  });

  @override
  Future<void> setUpAll() async {
    setUps++;
    await super.setUpAll();
  }

  @override
  Future<void> tearDownAll() async {
    tearDowns++;
    await super.tearDownAll();
  }
}
