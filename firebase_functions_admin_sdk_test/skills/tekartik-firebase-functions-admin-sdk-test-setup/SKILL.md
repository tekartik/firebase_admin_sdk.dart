---
name: tekartik-firebase-functions-admin-sdk-test-setup
description: >-
  Use when writing tests that exercise admin sdk Cloud Functions against a
  local http server, the firebase emulator or a deployed project with
  tekartik_firebase_functions_admin_sdk_test:
  FirebaseFunctionsAdminSdkTestContext, FirebaseFunctionsAdminSdkHttpTestContext,
  FirebaseFunctionsAdminSdkEmulatorTestContext,
  FirebaseFunctionsAdminSdkDeployedTestContext,
  FirebaseFunctionsAdminSdkTestContextSignInInfo, functionsHttpGroup,
  functionsCallGroup, functionsTaskGroup, functionsTaskFirestoreGroup,
  functionsPubsubGroup, functionsPubsubFirestoreGroup, waitForReceivedTasks,
  waitForReceivedMessages, ffAdminSdkCallTestGroup, httpsUri, enqueueTask,
  publishMessage.
---

# Functions test contexts and groups (tekartik_firebase_functions_admin_sdk_test)

Provides the shared test suite for admin sdk Cloud Functions and three
interchangeable contexts to run it against: a local http server, the firebase
emulator, or a deployed project. The functions the suite calls live in the same
package (see the `tekartik-firebase-functions-admin-sdk-test-functions` skill).

## Guidelines

* Depend on it with git (not on pub.dev), normally as a dev dependency:

  ```yaml
  dev_dependencies:
    tekartik_firebase_functions_admin_sdk_test:
      git:
        url: https://github.com/tekartik/firebase_admin_sdk.dart
        path: firebase_functions_admin_sdk_test
  ```

  Libraries: `test_context.dart` (the interface),
  `http_test_context.dart`, `emulator_test_context.dart`,
  `deployed_test_context.dart` (the three implementations),
  `functions_test_runner.dart` (the groups), `functions_call_test_runner.dart`
  (the callable client groups), `functions.dart` (the handlers and constants)
  and `menu/firebase_functions_menu.dart` (the dev menu). This package is VM
  only (`dart_test.yaml` pins `platforms: [vm]`, `concurrency: 1`).

* Everything is written against `FirebaseFunctionsAdminSdkTestContext`:
  `setUpAll()` / `tearDownAll()` (ref-counted, safe to call from several
  groups), `httpsUri(path)`, `client`, `enqueueTask(functionName, data)`,
  `publishMessage(topic, data)` and `signInInfo`. Write your own groups against
  that interface so they run unchanged on all three backends.

* `FirebaseFunctionsAdminSdkHttpTestContext({required app, required declarer,
  httpFactory, signInInfo})` starts an in-process
  `tekartik_firebase_functions_admin_sdk_http` server. `httpFactory` defaults
  to `httpFactoryIo`; pass `httpFactoryMemory` for a socket-free run. `app` is
  a `tekartik_firebase` app (`newFirebaseAppLocal()` /
  `newFirebaseAppMemory()`) on which you must register the products the
  handlers use (`newAuthServiceLocal().auth(app)`,
  `newFirestoreServiceMemory().firestore(app)`). `declarer` is the
  `TekartikFirebaseFunctionsAdminSdkHttpRunner` that registers the functions
  (`declareRunner`). `server` exposes the underlying `HttpServer`. Here
  `enqueueTask` and `publishMessage` post directly on the local server.

* `FirebaseFunctionsAdminSdkEmulatorTestContext({required emulatorOptions,
  region})` starts the firebase emulator from the current directory
  (`FirebaseEmulatorService(path: '.')`), so the test must run with the package
  root as working directory. Base url is
  `http://localhost:5001/<projectId>/<region>`, `region` defaulting to
  `regionUsCentral1`. Enable each emulator the functions need
  (`onlyFunctions`, `onlyAuth`, `onlyFirestore`, `onlyPubsub`). `enqueueTask`
  and `publishMessage` go through the deployed **test call function**, because
  only the function has admin credentials. `signInInfo` throws
  `UnimplementedError` on this context and on the deployed one.

* `FirebaseFunctionsAdminSdkDeployedTestContext({required urlSuffix, region})`
  targets real Cloud Run urls: `urlSuffix` is the part after the function name
  (`xxxxxx-ew.a.run.app`), so `httpsUri('admin-sdk-call-v1/x')` becomes
  `https://admin-sdk-call-v1-xxxxxx-ew.a.run.app/x`.

* Groups in `functions_test_runner.dart`, each taking the context:
  `functionsHttpGroup`, `functionsCallGroup`, `functionsTaskGroup`,
  `functionsTaskFirestoreGroup`, `functionsPubsubGroup`,
  `functionsPubsubFirestoreGroup`. Each calls `context.setUpAll()` in its own
  `setUpAll`, so wrap them in named `group(...)`s and call `tearDownAll()` once
  at the top level.

* Tasks and messages are asynchronous: poll with `waitForReceivedTasks(count)`
  / `waitForReceivedMessages(count)` (records written by the function to a
  temp file, only when the function runs on the test machine) or
  `waitForFirestoreTasks(context, count)` /
  `waitForFirestoreMessages(context, count)` (records read back from firestore
  through the call function, which also works on the emulator and deployed).
  Default timeout 30 s, they throw `StateError` on expiry. Never `expect` a
  record right after `enqueueTask` / `publishMessage`.

* For the callable client side use `functions_call_test_runner.dart`:
  `FirebaseFunctionsAdminSdkCallTestClientContext(functionsCall:, baseUrl:,
  signInInfo:)` where `baseUrl` contains `{{function}}` or `__function__` as
  the placeholder, then `ffAdminSdkCallTestGroup(() => clientContext)`. The
  `basicTestGroup` of `tekartik_firebase_functions_test` takes a
  `FirebaseFunctionsTestClientContext.urlTemplate(...)` built the same way.

* Emulator runs are slow: give the group
  `timeout: const Timeout(Duration(minutes: 5))`, skip the whole file when
  `await FirebaseEmulatorService(path: '.').isSupported()` is false, and delete
  `functions/functions.yaml` first so it is regenerated.

## Examples

### Local http server, in memory, with a signed in user

```dart
import 'package:tekartik_firebase_auth_local/auth_local.dart';
import 'package:tekartik_firebase_firestore_sembast/firestore_sembast.dart';
import 'package:tekartik_firebase_functions_admin_sdk_test/functions.dart';
import 'package:tekartik_firebase_functions_admin_sdk_test/functions_test_runner.dart';
import 'package:tekartik_firebase_functions_admin_sdk_test/http_test_context.dart';
import 'package:tekartik_firebase_functions_admin_sdk_test/test_context.dart';
import 'package:tekartik_firebase_local/firebase_local.dart';
import 'package:tekartik_http/http_memory.dart';
import 'package:test/test.dart';

Future<void> main() async {
  var app = newFirebaseAppMemory();
  var auth = newAuthServiceLocal().auth(app);
  newFirestoreServiceMemory().firestore(app);

  var signInInfo = FirebaseFunctionsAdminSdkTestContextSignInInfo(
    auth: auth,
    email: 'test@example.com',
    password: 'password',
  );
  await auth.signInOrUpWithEmailAndPassword(
    email: signInInfo.email,
    password: signInInfo.password,
  );
  await auth.signOut();

  var testContext = FirebaseFunctionsAdminSdkHttpTestContext(
    app: app,
    declarer: declareRunner,
    httpFactory: httpFactoryMemory,
    signInInfo: signInInfo,
  );
  group('firebase_functions_dart', () {
    setUpAll(() async {
      await testContext.setUpAll();
    });
    tearDownAll(() async {
      await testContext.tearDownAll();
    });
    group('https', () => functionsHttpGroup(testContext));
    group('call', () => functionsCallGroup(testContext));
    group('tasks', () => functionsTaskGroup(testContext));
    group('tasks firestore', () => functionsTaskFirestoreGroup(testContext));
    group('pubsub', () => functionsPubsubGroup(testContext));
    group('pubsub firestore', () => functionsPubsubFirestoreGroup(testContext));
  });
}
```

### Firebase emulator

```dart
@TestOn('vm')
library;

import 'dart:io';

import 'package:path/path.dart';
import 'package:tekartik_firebase_emulator/firebase_emulator.dart';
import 'package:tekartik_firebase_functions/firebase_functions.dart';
import 'package:tekartik_firebase_functions_admin_sdk_test/emulator_test_context.dart';
import 'package:tekartik_firebase_functions_admin_sdk_test/functions_test_runner.dart';
import 'package:test/test.dart';

var _emulatorService = FirebaseEmulatorService(path: '.');

Future<void> main() async {
  if (!await _emulatorService.isSupported()) {
    test('not_supported', () {}, skip: 'firebase emulator is not supported');
    return;
  }
  // Force re-generation of functions.yaml.
  var file = File(join('functions', 'functions.yaml'));
  if (file.existsSync()) {
    await file.delete();
  }
  final fbProjectId = await _emulatorService.getProjectId();

  var testContext = FirebaseFunctionsAdminSdkEmulatorTestContext(
    region: regionBelgium,
    emulatorOptions: FirebaseEmulatorOptions(
      onlyFunctions: true,
      onlyAuth: true,
      onlyFirestore: true,
      onlyPubsub: true,
      projectId: fbProjectId,
      debug: false,
    ),
  );
  group(
    'firebase_functions_dart',
    () {
      tearDownAll(() async {
        await testContext.tearDownAll();
      });
      group('https', () => functionsHttpGroup(testContext));
      group('tasks firestore', () => functionsTaskFirestoreGroup(testContext));
      group('pubsub firestore', () {
        functionsPubsubFirestoreGroup(testContext);
      });
    },
    timeout: const Timeout(Duration(minutes: 5)),
  );
}
```

### Callable client groups over the local server

```dart
library;

import 'package:tekartik_app_http/app_http.dart';
import 'package:tekartik_firebase_auth_local/auth_local.dart';
import 'package:tekartik_firebase_functions_admin_sdk_test/functions.dart';
import 'package:tekartik_firebase_functions_admin_sdk_test/functions_call_test_runner.dart';
import 'package:tekartik_firebase_functions_admin_sdk_test/http_test_context.dart';
import 'package:tekartik_firebase_functions_admin_sdk_test/test_context.dart';
import 'package:tekartik_firebase_functions_call_http/functions_call_memory.dart';
import 'package:tekartik_firebase_local/firebase_local.dart';
import 'package:test/test.dart';

void main() {
  late FirebaseFunctionsAdminSdkCallTestClientContext testClientContext;
  late FirebaseFunctionsAdminSdkHttpTestContext testServerContext;

  setUpAll(() async {
    var app = newFirebaseAppMemory();
    var prefix = 'adminsdkmemory';
    testServerContext = FirebaseFunctionsAdminSdkHttpTestContext(
      app: app,
      declarer: (functions) => declareRunner(functions, prefix: prefix),
      httpFactory: httpFactoryMemory,
    );
    var auth = authServiceLocal.auth(app);
    await auth.createUserWithEmailAndPassword(
      email: 'test@example.com',
      password: 'password',
    );
    await testServerContext.setUpAll();

    testClientContext = FirebaseFunctionsAdminSdkCallTestClientContext(
      // `__function__` (or `{{function}}`) is the placeholder.
      baseUrl: testServerContext.httpsUri('${prefix}__function__').toString(),
      functionsCall: firebaseFunctionsCallServiceMemory.functionsCall(
        app,
        options: FirebaseFunctionsCallOptions(region: regionBelgium),
      ),
      signInInfo: FirebaseFunctionsAdminSdkTestContextSignInInfo(
        auth: auth,
        email: 'test@example.com',
        password: 'password',
      ),
    );
  });
  tearDownAll(() async {
    await testServerContext.tearDownAll();
  });

  ffAdminSdkCallTestGroup(() => testClientContext);
}
```

### A custom group, backend agnostic

```dart
import 'package:tekartik_firebase_functions_admin_sdk_test/functions.dart';
import 'package:tekartik_firebase_functions_admin_sdk_test/functions_test_runner.dart';
import 'package:tekartik_firebase_functions_admin_sdk_test/test_context.dart';
import 'package:test/test.dart';

/// Works on the http, emulator and deployed contexts alike.
void myTaskGroup(FirebaseFunctionsAdminSdkTestContext context) {
  setUpAll(() async {
    await context.setUpAll();
  });

  test('enqueue two tasks, read them back from firestore', () async {
    await context.enqueueTask(testDartFunctionTaskFirestoreV1, {'i': 1});
    await context.enqueueTask(testDartFunctionTaskFirestoreV1, {'i': 2});

    // Never assert right away, poll instead.
    var tasks = await waitForFirestoreTasks(
      context,
      2,
      timeout: const Duration(seconds: 60),
    );
    expect(tasks, hasLength(2));
  });

  test('pub/sub, records on the test machine only', () async {
    // `testPubsubRecordList` reads a temp file written by the function, so it
    // only works when the functions run locally (http context).
    await testPubsubRecordClear();
    await context.publishMessage(testDartPubsubTopicV1, {'i': 1});
    var messages = await waitForReceivedMessages(1);
    expect(messages.first['data'], {'i': 1});
  });
}
```
