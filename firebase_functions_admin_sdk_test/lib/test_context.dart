import 'dart:async';
import 'package:tekartik_http/http_client.dart';

abstract class FirebaseFunctionsAdminSdkTestContext {
  FutureOr<void> setUpAll();
  FutureOr<void> tearDownAll();

  Uri httpsUri(String path);
  Client get client;
}
