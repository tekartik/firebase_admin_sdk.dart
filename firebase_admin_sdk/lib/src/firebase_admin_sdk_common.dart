import 'package:tekartik_firebase/firebase_admin.dart';
import 'package:tekartik_firebase_auth/auth.dart';
import 'package:tekartik_firebase_firestore/firestore.dart';
import 'package:tekartik_firebase_storage/storage.dart';

/// Auth service for admin sdk.
abstract class FirebaseAuthServiceAdminSdk implements FirebaseAuthService {}

/// Firestore service for admin sdk.
abstract class FirebaseFirestoreServiceAdminSdk implements FirestoreService {}

/// Storage service for admin sdk.
abstract class FirebaseStorageServiceAdminSdk
    implements FirebaseStorageService {}

/// AdminSdk extension (if any)
abstract class FirebaseAdminSdk implements Firebase, FirebaseAdmin {
  /// Initialize rest with a service account json map.
  Future<FirebaseApp> initializeAppWithServiceAccountMap(
    Map map, {

    /// Overiden options (storage bucket, database url, ...)
    FirebaseAppOptions? options,
  });
}

/// AdminSdk app extension (if any)
abstract class FirebaseAppAdminSdk implements FirebaseApp {}
