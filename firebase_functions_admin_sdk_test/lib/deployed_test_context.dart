import 'dart:async';

import 'package:tekartik_app_http/app_http.dart';
import 'package:tekartik_firebase_functions_admin_sdk_test/test_context.dart';

/// HTTP test context for Firebase Functions Admin SDK.
class FirebaseFunctionsAdminSdkDeployedTestContext
    implements FirebaseFunctionsAdminSdkTestContext {
  // https://admin-sdk-https-v1-xxxxxx-ew.a.run.app
  /// xxxxxx-ew.a.run.app
  final String urlSuffix;
  var _refCount = 0;

  /// The HTTP factory.
  final HttpClientFactory httpClientFactory;

  @override
  Future<void> setUpAll() async {
    if (_refCount++ == 0) {}
  }

  @override
  Future<void> tearDownAll() async {
    if (--_refCount == 0) {
      client.close();
    }
  }

  @override
  Uri httpsUri(String path) {
    var fn = path.split('/').first;
    path = path.substring(fn.length);
    if (!path.startsWith('/')) {
      path = '/$path';
    }
    return Uri.parse('https://$fn-$urlSuffix').replace(path: path);
  }

  @override
  late final client = httpClientFactory.newClient();

  /// Creates an HTTP test context.
  FirebaseFunctionsAdminSdkDeployedTestContext({required this.urlSuffix})
    : httpClientFactory = httpClientFactoryUniversal;

  @override
  // TODO: implement signInInfo
  FirebaseFunctionsAdminSdkTestContextSignInInfo? get signInInfo =>
      throw UnimplementedError();
}
