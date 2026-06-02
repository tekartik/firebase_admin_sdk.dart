import 'package:tekartik_firebase_admin_sdk/firebase_admin_sdk.dart';
import 'package:tekartik_firebase_admin_sdk/firebase_auth_admin_sdk.dart';
import 'package:tekartik_firebase_admin_sdk/firebase_storage_admin_sdk.dart';
import 'package:tekartik_firebase_admin_sdk/firestore_admin_sdk.dart';

/// Firebase admin sdk for web.
FirebaseAdminSdk get firebaseAdminSdk =>
    throw UnsupportedError('firebaseAdminSdk is not supported on web');

/// Auth service for admin sdk.
FirebaseAuthServiceAdminSdk get firebaseAuthServiceAdminSdk =>
    throw UnsupportedError(
      'firebaseAuthServiceAdminSdk is not supported on web',
    );

/// Storage service for admin sdk.
FirebaseStorageServiceAdminSdk get firebaseStorageServiceAdminSdk =>
    throw UnsupportedError(
      'firebaseStorageServiceAdminSdk is not supported on web',
    );

/// Firestore service for admin sdk.
FirebaseFirestoreServiceAdminSdk get firestoreServiceAdminSdk =>
    throw UnsupportedError('firestoreServiceAdminSdk is not supported on web');
