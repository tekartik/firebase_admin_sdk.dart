# tekartik_firebase_functions_admin_sdk_http

Runs the handlers written for `tekartik_firebase_functions_admin_sdk` (the
Dart Cloud Functions runtime, `package:firebase_functions`) on a plain
`tekartik_http` server, in memory or on a real port: tests and local dev runs
need neither the firebase emulator nor a deployment. One url path per
function (`/<name>`). Dart VM only.

## Getting started

Not on pub.dev, add it as a git dependency (with the admin sdk functions, for
`Request`, `Response`, `CallableResult`...):

```yaml
dependencies:
  tekartik_firebase_functions_admin_sdk:
    git:
      url: https://github.com/tekartik/firebase_admin_sdk.dart
      path: firebase_functions_admin_sdk
  tekartik_firebase_functions_admin_sdk_http:
    git:
      url: https://github.com/tekartik/firebase_admin_sdk.dart
      path: firebase_functions_admin_sdk_http
```

A memory server and a call, in one process (a test):

```dart
import 'package:tekartik_firebase_functions_admin_sdk/functions_admin_sdk.dart';
import 'package:tekartik_firebase_functions_admin_sdk_http/functions_admin_sdk_http.dart';
import 'package:tekartik_firebase_local/firebase_local.dart';
import 'package:tekartik_http/http_memory.dart';

Future<void> main() async {
  late FirebaseFunctionsAdminSdkHttp functions;
  // In memory by default; port 0 for any free port (4999 by default).
  var service = FirebaseFunctionsServiceAdminSdkHttp(port: 0);
  await service.fireUp(newFirebaseAppMemory(), (registered) {
    functions = registered;
    registered.https.onAdminSdkRequest(
      'hello',
      (_, request) => Response.ok('Hello ${request.url.path}'),
    );
  });
  var client = httpClientFactoryMemory.newClient();
  var uri = httpServerGetUri(functions.httpServer);
  print(await client.read(uri.replace(path: '/hello/world'))); // Hello world
  client.close();
  await functions.httpServer.close();
}
```

For a dev server on a real port pass `httpServerFactory: httpServerFactoryIo`
(`tekartik_http_io`) and a port.

## When to use what

* `https.onAdminSdkRequest(name, handler)`: a raw http function
  (`Request` in, `Response` out).
* `https.onAdminSdkCall(name, handler)`: a callable (`{"data": ...}` posted,
  `{"result": ...}` answered).
* `tasks.onAdminSdkTaskDispatched(name, handler)`: a task queue function (a
  `{"data": ...}` post, answered 204).
* `pubsub.onAdminSdkMessagePublished(name, topic:, handler:)`: a pub/sub
  function (the cloud event json of `pubsubMessagePublishedCloudEventJson`),
  `pubsub.functionNameForTopic(topic)` gives its path.

## What to know

* Register everything in the `fireUp` runner: the server starts once it
  returns. Keep the `FirebaseFunctionsAdminSdkHttp` it gets to read
  `httpServer` (its port) and to close it.
* Requests are served concurrently, a function may call another one of the
  same server.
* The handler sees the path of the deployed function: without the function
  name (`/hello/sub` gives `requestedUri.path` `/sub`, `request.url`
  `sub`; `/hello` gives `/`), as `package:firebase_functions` does.
* The caller uid of a callable or a task comes from the
  `x-tekartik-firebase-call-uid` header (`firebaseFunctionsHttpHeaderUid`),
  not from a verified token, and the server listens on all the interfaces:
  a development tool, not a production server.
* A handler error is answered 500. A callable error keeps its code when it
  is an `HttpResponseException` (`FirebaseFunctionsHttpsError(...).toAdminSdk()`),
  anything else is `INTERNAL`.
* `https.onRequest`, `https.onCall` (the `tekartik_firebase_functions`
  abstraction) are not implemented here: use the `onAdminSdk*` methods.

The agent skill
[tekartik-firebase-functions-admin-sdk-http-setup](skills/tekartik-firebase-functions-admin-sdk-http-setup/SKILL.md)
has more examples (the four trigger kinds, tasks and pub/sub deliveries).
