// Firestore and Auth with admin credentials.
//
// Run it on the emulators (no credentials needed with a `demo-` project):
//
//   firebase emulators:start --only firestore,auth --project demo-example
//   export FIRESTORE_EMULATOR_HOST=127.0.0.1:8080
//   export FIREBASE_AUTH_EMULATOR_HOST=127.0.0.1:9099
//   dart run example/main.dart
//
// On Cloud Run or Cloud Functions, without the exports, the application
// default credentials and the project of the environment are used.
// ignore_for_file: avoid_print
library;

import 'package:tekartik_firebase_admin_sdk/firebase_admin_sdk.dart';
import 'package:tekartik_firebase_admin_sdk/firebase_auth_admin_sdk.dart';
import 'package:tekartik_firebase_admin_sdk/firestore_admin_sdk.dart';
import 'package:tekartik_firebase_auth/auth_admin.dart';

Future<void> main() async {
  var app = firebaseAdminSdk.initializeApp(
    options: AppOptions(projectId: 'demo-example'),
  );
  try {
    // Firestore
    var firestore = firestoreServiceAdminSdk.firestore(app);
    var users = firestore.collection('users');
    await users.doc('alice').set({'name': 'Alice', 'age': 30});
    var adults = await users.where('age', isGreaterThanOrEqualTo: 18).get();
    print(adults.docs.map((doc) => doc.ref.id).toList());

    // Auth (admin)
    var auth = firebaseAuthServiceAdminSdk.auth(app) as FirebaseAuthAdmin;
    var user =
        await auth.getUserByEmail('alice@example.com') ??
        await auth.createUser(
          FirebaseAuthCreateUserRequest(
            email: 'alice@example.com',
            password: 'a-strong-password',
            displayName: 'Alice',
          ),
        );
    print('${user.uid} ${user.displayName}');
  } finally {
    await app.delete();
  }
}
