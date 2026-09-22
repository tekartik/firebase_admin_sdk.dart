# tekartik_firebase_functions_admin_sdk_http

Raw http implementation

## Setup

In `pubspec.yaml`:
```yaml
  tekartik_firebase_functions_admin_sdk_http:
    git:
      url: https://github.com/tekartik/firebase_admin_sdk.dart
      path: firebase_functions_admin_sdk_http
```

## Usage

```dart
// A local dev server on port 8040 (4999 by default, 0 for any free port).
var service = FirebaseFunctionsServiceAdminSdkHttp(
  httpServerFactory: httpServerFactoryIo,
  port: 8040,
);
await service.fireUp(app, (functions) {
  functions.https.onAdminSdkRequest('hello', (_, request) => Response.ok('hi'));
});
// hello http://localhost:8040/hello
```
