# firebase_admin_sdk.dart

Tekartik Firebase implementations on top of the Dart
[firebase_admin_sdk](https://pub.dev/packages/firebase_admin_sdk): server side
code (Cloud Run, Cloud Functions in Dart, scripts) written against the
platform neutral tekartik Firebase packages. Git packages, not on pub.dev.

| Package | Path | What |
|---|---|---|
| `tekartik_firebase_admin_sdk` | [firebase_admin_sdk](firebase_admin_sdk) | `FirebaseApp`, Firestore, Auth (admin), Storage, Pub/Sub, Cloud Tasks; start here |
| `tekartik_firebase_functions_admin_sdk` | [firebase_functions_admin_sdk](firebase_functions_admin_sdk) | Cloud Functions written in Dart (https, callable, Pub/Sub, tasks) |
| `tekartik_firebase_functions_admin_sdk_http` | [firebase_functions_admin_sdk_http](firebase_functions_admin_sdk_http) | raw http implementation of these functions |
| `tekartik_firebase_admin_sdk_test` | [firebase_admin_sdk_test](firebase_admin_sdk_test) | tests against the Firebase emulators |

See the [firebase_admin_sdk package README](firebase_admin_sdk/README.md) to
get started.
