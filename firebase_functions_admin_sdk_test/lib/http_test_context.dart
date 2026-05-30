import 'dart:async';

import 'package:path/path.dart';
import 'package:tekartik_firebase_functions_admin_sdk_http/functions_admin_sdk_http.dart';
import 'package:tekartik_firebase_functions_admin_sdk_test/test_context.dart';
import 'package:tekartik_firebase_functions_call/functions_call.dart';
import 'package:tekartik_http_io/http_io.dart';

/// HTTP test context for Firebase Functions Admin SDK.
class FirebaseFunctionsAdminSdkHttpTestContext
    implements FirebaseFunctionsAdminSdkTestContext {
  var _refCount = 0;

  /// The HTTP factory.
  final HttpFactory httpFactory;

  /// The runner function to declare functions.
  final TekartikFirebaseFunctionsAdminSdkHttpRunner declarer;

  /// The Firebase application.
  final FirebaseApp app;

  /// The Firebase functions admin SDK instance.
  late FirebaseFunctionsAdminSdkHttp functions;
  @override
  Future<void> setUpAll() async {
    if (_refCount++ == 0) {
      var service = FirebaseFunctionsServiceAdminSdkHttp(
        httpServerFactory: httpFactory.server,
      );
      await service.fireUp(app, (functions) async {
        this.functions = functions;
        await declarer(functions);
      });
    }
  }

  @override
  Future<void> tearDownAll() async {
    if (--_refCount == 0) {
      client.close();
    }
  }

  late final _server = httpServerGetUri(functions.httpServer);
  @override
  Uri httpsUri(String path) =>
      _server.replace(path: url.join(_server.path, path));

  @override
  late final client = httpFactory.client.newClient();

  /// Creates an HTTP test context.
  FirebaseFunctionsAdminSdkHttpTestContext({
    HttpFactory? httpFactory,
    required this.declarer,
    required this.app,
  }) : httpFactory = httpFactory ?? httpFactoryIo;
}
