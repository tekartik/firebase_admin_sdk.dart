# tekartik_firebase_functions_admin_sdk

Dart Cloud Functions (the native Dart runtime of `package:firebase_functions`)
written against the `tekartik_firebase_functions` abstractions, with the
Firebase admin products of `tekartik_firebase_admin_sdk` (Firestore, Auth,
Storage, Cloud Tasks, Pub/Sub). Dart VM only.

## Getting started

Not on pub.dev, add it as a git dependency of the functions package (the
`functions/` folder deployed by `firebase deploy`, `"runtime": "dart3"`):

```yaml
dependencies:
  tekartik_firebase_functions_admin_sdk:
    git:
      url: https://github.com/tekartik/firebase_admin_sdk.dart
      path: firebase_functions_admin_sdk
```

`functions/bin/server.dart`:

```dart
import 'package:tekartik_firebase_admin_sdk/firestore_admin_sdk.dart';
import 'package:tekartik_firebase_functions_admin_sdk/functions_admin_sdk.dart';

Future<Response> helloHandler(
  FirebaseFunctions firebaseFunctions,
  Request request,
) async => Response.ok('Hello');

Future<CallableResult<Map<String, Object?>>> meHandler(
  FirebaseFunctions firebaseFunctions,
  CallableRequest<Object?> request,
  CallableResponse<Map<String, Object?>> response,
) async {
  var uid = request.auth?.uid;
  if (uid == null) {
    throw FirebaseFunctionsHttpsError(
      FirebaseFunctionsHttpsErrorCode.unauthenticated,
      'Sign in first',
    ).toAdminSdk();
  }
  return CallableResult({'uid': uid});
}

void main(List<String> args) {
  runFunctions((firebase) {
    // The products the handlers read with app.getProduct<Firestore>().
    firestoreServiceAdminSdk.firestore(firebase.firebaseApp);
    firebase.https.onRequest(
      firebase.httpsHandler(helloHandler),
      name: 'hello',
      options: const HttpsOptions(region: Region(SupportedRegion.europeWest1)),
    );
    firebase.https.onCall(
      firebase.callHandler(meHandler),
      name: 'me',
      options: const CallableOptions(
        region: Region(SupportedRegion.europeWest1),
      ),
    );
  });
}
```

## What to know

* Function names and options must be `const`: `package:firebase_functions`
  generates `functions.yaml` from them (a computed option gives no
  endpoint).
* In a native handler (`firebase.callHandler`), throw
  `FirebaseFunctionsHttpsError(...).toAdminSdk()`: any other exception is
  answered 500 `INTERNAL`. A callable registered through the abstraction
  (`firebaseFunctionsServiceAdminSdk.fireUp`, `functions.https.onCall`)
  converts a thrown `FirebaseFunctionsHttpsError` itself and answers a null
  result as `{"result": null}`; `functions.https.onRequest` is not supported
  there (use `firebase.https.onRequest`).
* `isFunctionsEmulator` (`functions_emulator.dart`, web safe) tells whether
  the functions emulator runs the code.
* Task queue and Pub/Sub triggers: [doc/tasks.md](doc/tasks.md),
  [doc/pubsub.md](doc/pubsub.md).

The agent skills
[tekartik-firebase-functions-admin-sdk-setup](skills/tekartik-firebase-functions-admin-sdk-setup/SKILL.md)
and
[tekartik-firebase-functions-admin-sdk-triggers](skills/tekartik-firebase-functions-admin-sdk-triggers/SKILL.md)
have more examples.
