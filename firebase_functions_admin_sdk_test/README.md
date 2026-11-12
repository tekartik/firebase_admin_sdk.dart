# tekartik_firebase_functions_admin_sdk_test

The shared test suite of the admin sdk Cloud Functions (https, callable, task
dispatched and pub/sub functions), the test functions it calls, and three
contexts to run it against:

- `FirebaseFunctionsAdminSdkHttpTestContext`: the functions served in process
  by `tekartik_firebase_functions_admin_sdk_http` (io or memory http server,
  any free port), no emulator, no project;
- `FirebaseFunctionsAdminSdkEmulatorTestContext`: the firebase emulator
  (firebase cli and java needed);
- `FirebaseFunctionsAdminSdkDeployedTestContext`: functions deployed on a
  project (`functions/bin/server.dart`).

Dart VM only (`dart_test.yaml`: `platforms: [vm]`, `concurrency: 1`).

## Getting started

Not on pub.dev, a git dev dependency:

```yaml
dev_dependencies:
  tekartik_firebase_functions_admin_sdk_test:
    git:
      url: https://github.com/tekartik/firebase_admin_sdk.dart
      path: firebase_functions_admin_sdk_test
```

The whole suite against an in memory server:

```dart
import 'package:tekartik_firebase_auth_local/auth_local.dart';
import 'package:tekartik_firebase_firestore_sembast/firestore_sembast.dart';
import 'package:tekartik_firebase_functions_admin_sdk_test/functions.dart';
import 'package:tekartik_firebase_functions_admin_sdk_test/functions_test_runner.dart';
import 'package:tekartik_firebase_functions_admin_sdk_test/http_test_context.dart';
import 'package:tekartik_firebase_local/firebase_local.dart';
import 'package:tekartik_http/http_memory.dart';
import 'package:test/test.dart';

void main() {
  var app = newFirebaseAppMemory();
  newAuthServiceLocal().auth(app);
  newFirestoreServiceMemory().firestore(app);
  var context = FirebaseFunctionsAdminSdkHttpTestContext(
    app: app,
    declarer: declareRunner,
    httpFactory: httpFactoryMemory,
  );
  group('admin_sdk', () {
    // Holds the context (server and client) for all the groups.
    setUpAll(context.setUpAll);
    tearDownAll(context.tearDownAll);
    group('https', () => functionsHttpGroup(context));
    group('call', () => functionsCallGroup(context));
    group('tasks', () => functionsTaskGroup(context));
    group('pubsub', () => functionsPubsubGroup(context));
  });
}
```

`setUpAll` / `tearDownAll` are reference counted: the first call starts the
server, the last one closes it and the client; a later `setUpAll` starts them
again.

## Running the tests of this package

`dart test` runs the http (io and memory) tests. `test/emulator_test.dart`
starts the emulator on the project of the local `.firebaserc`, not on a
`demo-` project: the functions run with the credentials of the machine, and a
call to a service whose emulator is not started (Cloud Tasks) reaches that
project. Run it on purpose only (it is skipped when the firebase cli is
missing). For your own emulator tests, use a `demo-` project id.

More: the package skills in `skills/` (the contexts and groups, the test
functions).
