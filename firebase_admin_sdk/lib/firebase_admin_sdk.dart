/// Firebase apps with admin credentials (`firebaseAdminSdk`), Dart VM only.
///
/// Get the products with the services of the other libraries of this package
/// (`firestore_admin_sdk.dart`, `firebase_auth_admin_sdk.dart`...).
library;

export 'package:tekartik_firebase/firebase.dart';
export 'src/firebase_admin_sdk_common.dart'
    show FirebaseAdminSdk, FirebaseAppAdminSdk;

export 'src/platform/platform.dart' show firebaseAdminSdk;
