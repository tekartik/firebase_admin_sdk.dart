import 'dart:async';
import 'package:tekartik_firebase_admin_sdk/firebase_auth_admin_sdk.dart';
import 'package:tekartik_http/http_client.dart';

/// Test context interface for Firebase Functions Admin SDK.
abstract class FirebaseFunctionsAdminSdkTestContext {
  /// Setup method called once before all tests.
  FutureOr<void> setUpAll();

  /// Teardown method called once after all tests.
  FutureOr<void> tearDownAll();

  /// Gets the HTTPS URI for the given path.
  Uri httpsUri(String path);

  /// HTTP client used to perform requests.
  Client get client;

  /// Sign in info
  FirebaseFunctionsAdminSdkTestContextSignInInfo? get signInInfo;
}

/// Sign in info for Firebase Functions Admin SDK.
class FirebaseFunctionsAdminSdkTestContextSignInInfo {
  /// Authentication service.
  final FirebaseAuth auth;

  /// User email.
  final String email;

  /// User password.
  final String password;

  /// Creates a sign in info.
  FirebaseFunctionsAdminSdkTestContextSignInInfo({
    required this.auth,
    required this.email,
    required this.password,
  });
}
