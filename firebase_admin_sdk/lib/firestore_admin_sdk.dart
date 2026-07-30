export 'package:tekartik_firebase_firestore/firestore.dart';

export 'src/firebase_admin_sdk_common.dart'
    show FirebaseFirestoreServiceAdminSdk;
// The native instance is the only way to reach what the tekartik abstraction
// does not cover, `listDocuments()` on a collection in particular: it lists
// the documents of a collection including the ones that do not exist but hold
// sub collections, which a query never returns.
export 'src/firebase_firestore_admin_sdk.dart' show FirestoreAdminSdk;
export 'src/platform/platform.dart' show firestoreServiceAdminSdk;
