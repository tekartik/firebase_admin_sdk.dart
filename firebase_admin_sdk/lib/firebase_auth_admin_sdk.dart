/// Auth with admin credentials: `firebaseAuthServiceAdminSdk.auth(app)`, also
/// a `FirebaseAuthAdmin` (`package:tekartik_firebase_auth/auth_admin.dart`).
library;

export 'package:tekartik_firebase_auth/auth.dart';

export 'src/firebase_admin_sdk_common.dart' show FirebaseAuthServiceAdminSdk;

export 'src/platform/platform.dart' show firebaseAuthServiceAdminSdk;
