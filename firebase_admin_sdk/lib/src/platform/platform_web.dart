/*import 'package:tekartik_firebase_admin_sdk/firebase_admin_sdk.dart';
import 'package:tekartik_firebase_admin_sdk/firebase_auth_admin_sdk.dart';
import 'package:tekartik_firebase_admin_sdk/firebase_storage_admin_sdk.dart';
import 'package:tekartik_firebase_admin_sdk/firebase_pubsub_admin_sdk.dart';
import 'package:tekartik_firebase_admin_sdk/firebase_tasks_admin_sdk.dart';
import 'package:tekartik_firebase_admin_sdk/firestore_admin_sdk.dart';
*/
import 'package:tekartik_firebase_admin_sdk/src/firebase_admin_sdk_common.dart';

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

/// Tasks service for admin sdk.
FirebaseTasksServiceAdminSdk get firebaseTasksServiceAdminSdk =>
    throw UnsupportedError(
      'firebaseTasksServiceAdminSdk is not supported on web',
    );

/// Pub/Sub service for admin sdk.
FirebasePubsubServiceAdminSdk get firebasePubsubServiceAdminSdk =>
    throw UnsupportedError(
      'firebasePubsubServiceAdminSdk is not supported on web',
    );

/// Pub/Sub emulator host, always null on the web.
String? get pubsubEmulatorHost => null;
