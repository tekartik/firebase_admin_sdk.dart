---
name: tekartik-firebase-functions-admin-sdk-setup
description: >-
  Use when writing a Dart Cloud Functions server (bin/server.dart) deployed as
  a native Dart runtime function and reaching Firebase with admin credentials:
  runFunctions, firebaseFunctionsServiceAdminSdk, fireUp, firebase.firebaseApp,
  firebase.httpsHandler / firebase.callHandler, onRequest / onCall,
  HttpsOptions, CallableOptions, Region, Cors, Instances, TimeoutSeconds,
  CallableRequest, CallableResult, Response, Request, and mapping
  FirebaseFunctionsHttpsError / FirebaseFunctionsHttpsErrorCode to the admin
  sdk error with toAdminSdk() in tekartik_firebase_functions_admin_sdk.
---

# tekartik_firebase_functions_admin_sdk setup (tekartik_firebase_functions_admin_sdk)

Implements `tekartik_firebase_functions` on top of `package:firebase_functions`
(the Dart Cloud Functions runtime) and `tekartik_firebase_admin_sdk`, so
handlers written against the tekartik abstractions can be deployed as real
Cloud Functions. Dart VM only: on the web the library resolves to a stub.

## Guidelines

* Depend on it with git (not on pub.dev):

  ```yaml
  dependencies:
    tekartik_firebase_functions_admin_sdk:
      git:
        url: https://github.com/tekartik/firebase_admin_sdk.dart
        path: firebase_functions_admin_sdk
  ```

  A single import gives everything:
  `import 'package:tekartik_firebase_functions_admin_sdk/functions_admin_sdk.dart';`.
  It re-exports `package:firebase_functions` (`runFunctions`, `Request`,
  `Response`, `CallableRequest`, `CallableResponse`, `CallableResult`,
  `HttpsOptions`, `CallableOptions`, `Region`, `SupportedRegion`, `Cors`,
  `Instances`, `TimeoutSeconds`, ...) plus `FirebaseFunctions` and
  `FirebaseFunctionsService` from `tekartik_firebase_functions`.

* The deployed entry point is a separate `functions/` package with its own
  `pubspec.yaml`, `bin/server.dart` and a `build_runner` dev dependency on
  `firebase_functions`, referenced from `firebase.json`
  (`"source": "functions", "runtime": "dart3"`). `functions.yaml` is generated
  by `package:firebase_functions`, which is why **every option passed to
  `onRequest` / `onCall` / `onTaskDispatched` / `onMessagePublished` must be a
  `const`**: a computed option silently produces no endpoint. Compile with
  `dart compile exe bin/server.dart --target-os=linux --target-arch=x64`.

* Register with the native namespaces and wrap the handler with the extension
  on `Firebase` (`FirebaseFunctionsAdminSdkFirebaseExt`):
  `firebase.https.onRequest(firebase.httpsHandler(handler), name: ..., options: const HttpsOptions(...))`
  and
  `firebase.https.onCall(firebase.callHandler(handler), name: ..., options: const CallableOptions(...))`.
  The wrapper builds a `FirebaseFunctionsAdminSdk` and passes it as the first
  argument of the handler, so handler code only ever sees the abstractions
  (`FirebaseFunctionsAdminSdkRequestHandler`,
  `FirebaseFunctionsAdminSdkCallHandler<T>`).

* `firebase.firebaseApp` wraps the native admin app into a
  `FirebaseAppAdminSdk` (created once per process). Initialize the products
  you need inside the `runFunctions` builder
  (`firestoreServiceAdminSdk.firestore(app)`,
  `firebaseAuthServiceAdminSdk.auth(app)`), then inside a handler read them
  back with `firebaseFunctions.app.getProduct<Firestore>()`: a product that
  was never initialized in the builder is `null`.

* Anti-pattern: `firebaseFunctionsServiceAdminSdk.functions(app)` throws
  `UnimplementedError`, and registering an `https.onRequest` built from the
  abstracted `FirebaseFunctionsAdminSdk.https` throws `UnsupportedError`. The
  abstract `fireUp(runner)` entry point exists (it calls `runFunctions` and
  hands a `FirebaseFunctionsAdminSdk`) and is fine for callable, task and
  pub/sub functions registered through `functions['name'] = ...`, but plain
  http functions must go through `firebase.https.onRequest`.

* Errors: `FirebaseFunctionsHttpsError` / `FirebaseFunctionsHttpsErrorCode`
  are the tekartik `HttpsError` / `HttpsErrorCode`; the native error is
  `FirebaseFunctionsAdminSdkHttpsError` (`HttpResponseException`). Throw
  `myError.toAdminSdk()` from a handler. `toAdminSdk()` maps every code to its
  http status (`invalidArgument` -> 400, `notFound` -> 404,
  `permissionDenied` -> 403, `unauthenticated` -> 401, `cancelled` -> 499,
  ...); `ok` or an unknown code becomes `500`/`UNKNOWN` with the original code
  prefixed in the message, and an empty message falls back to the code. Non
  map `details` are wrapped in `{'details': value}` because the native error
  only accepts a list of string keyed maps.

* Regions: options take the native `Region(SupportedRegion.europeWest1)`.
  `wrapRegion(String?)` (from `src/functions_admin_sdk.dart`) converts a
  tekartik region string such as `regionBelgium` and throws `ArgumentError`
  for an unsupported one. `wrapGlobalOptions`, `wrapCors`, `wrapInstances` and
  `wrapTimeoutSeconds` do the same for the other options.

* Emulator: `FirebaseFunctionsAdminSdkExt.isEmulator` reads the
  `FIREBASE_EMULATOR` environment variable (`'true'`), set by the firebase
  emulator suite. Cast the handler argument
  (`firebaseFunctions as FirebaseFunctionsAdminSdk`) to reach it.

* For a local, emulator-free http server hosting the same handlers use
  `tekartik_firebase_functions_admin_sdk_http`; for the shared test suite and
  the emulator/deployed test contexts use
  `tekartik_firebase_functions_admin_sdk_test`. Task queue and Pub/Sub
  triggers are covered by the
  `tekartik-firebase-functions-admin-sdk-triggers` skill.

## Examples

### `functions/bin/server.dart`: http and callable functions

```dart
import 'package:tekartik_firebase_admin_sdk/firebase_auth_admin_sdk.dart';
import 'package:tekartik_firebase_admin_sdk/firestore_admin_sdk.dart';
import 'package:tekartik_firebase_functions_admin_sdk/functions_admin_sdk.dart';

Future<Response> helloHandler(
  FirebaseFunctions firebaseFunctions,
  Request request,
) async {
  return Response.ok('Hello from ${request.requestedUri}');
}

Future<CallableResult<Map<String, Object?>>> meHandler(
  FirebaseFunctions firebaseFunctions,
  CallableRequest<Object?> request,
  CallableResponse<Map<String, Object?>> response,
) async {
  return CallableResult({'uid': request.auth?.uid, 'data': request.data});
}

void main(List<String> args) {
  runFunctions((firebase) {
    // Initialize the products the handlers will need.
    var app = firebase.firebaseApp;
    firestoreServiceAdminSdk.firestore(app);
    firebaseAuthServiceAdminSdk.auth(app);

    firebase.https.onRequest(
      firebase.httpsHandler(helloHandler),
      name: 'hello',
      options: const HttpsOptions(
        cors: Cors(['*']),
        region: Region(SupportedRegion.europeWest1),
        maxInstances: Instances(11),
        timeoutSeconds: TimeoutSeconds(19),
      ),
    );
    firebase.https.onCall(
      firebase.callHandler(meHandler),
      name: 'me',
      options: const CallableOptions(
        cors: Cors(['*']),
        region: Region(SupportedRegion.europeWest1),
      ),
    );
  });
}
```

### Reading firestore from a callable and failing with an https error

```dart
import 'package:tekartik_firebase_firestore/firestore.dart';
import 'package:tekartik_firebase_functions_admin_sdk/functions_admin_sdk.dart';

/// Throws a `PERMISSION_DENIED` (403) / `NOT_FOUND` (404) admin sdk error.
Future<CallableResult<Map<String, Object?>>> profileHandler(
  FirebaseFunctions firebaseFunctions,
  CallableRequest<Object?> request,
  CallableResponse<Map<String, Object?>> response,
) async {
  var uid = request.auth?.uid;
  if (uid == null) {
    throw FirebaseFunctionsHttpsError(
      FirebaseFunctionsHttpsErrorCode.permissionDenied,
      'Sign in first',
    ).toAdminSdk();
  }
  // Initialized in the runFunctions builder.
  var firestore = firebaseFunctions.app.getProduct<Firestore>()!;
  var snapshot = await firestore.doc('users/$uid').get();
  if (!snapshot.exists) {
    throw FirebaseFunctionsHttpsError(
      FirebaseFunctionsHttpsErrorCode.notFound,
      'No profile',
      {'uid': uid},
    ).toAdminSdk();
  }
  return CallableResult(snapshot.data);
}
```

### Registering through the abstraction (`fireUp`)

```dart
import 'package:tekartik_firebase_functions_admin_sdk/functions_admin_sdk.dart';

Future<void> main() async {
  await firebaseFunctionsServiceAdminSdk.fireUp((functions) {
    print('emulator: ${functions.isEmulator}');
    // `functions.https.onRequest(...)` is NOT supported here, use
    // `firebase.https.onRequest` in a runFunctions builder instead.
    functions['echo'] = functions.https.onCall(
      (request) async => <String, Object?>{'echo': request.data},
    );
  });
}
```
