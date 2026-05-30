import 'dart:async';
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
}
