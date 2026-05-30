import 'dart:async';

import 'package:tekartik_firebase_functions/firebase_functions.dart';
import 'package:tekartik_firebase_functions_admin_sdk/functions_admin_sdk.dart';
import 'package:tekartik_firebase/firebase_mixin.dart';

/// Callback type for the Admin SDK function registration.
typedef TekartikFirebaseFunctionsAdminSdkHttpRunner =
    FutureOr<void> Function(FirebaseFunctionsAdminSdkHttp functions);

abstract class FirebaseFunctionsServiceAdminSdkHttp
    implements FirebaseFunctionsService {
  Future<void> fireUp(TekartikFirebaseFunctionsAdminSdkHttpRunner runner);
}

abstract class FirebaseFunctionsAdminSdkHttp implements FirebaseFunctions {}

class _FirebaseFunctionsServiceAdminSdkHttp
    with
        FirebaseProductServiceMixin<FirebaseFunctions>,
        FirebaseFunctionsServiceDefaultMixin
    implements FirebaseFunctionsServiceAdminSdkHttp {
  @override
  FirebaseFunctionsAdminSdk functions(FirebaseApp app) {
    throw UnimplementedError(
      'Use fireUp() for Admin SDK functions registration',
    );
  }

  @override
  Future<void> fireUp(
    TekartikFirebaseFunctionsAdminSdkHttpRunner runner,
  ) async {
    // TODO
  }
}

class _FirebaseFunctionsAdminSdkHttp
    with
        FirebaseAppProductMixin<FirebaseFunctions>,
        FirebaseFunctionsDefaultMixin
    implements FirebaseFunctions {
  @override
  final _FirebaseFunctionsServiceAdminSdkHttp service;

  _FirebaseFunctionsAdminSdkHttp({required this.service});
  /*
  @override
  FirebaseFunctionsAdminSdkHttpsNamespace get httpsAdminSdk =>
      throw UnimplementedError('httpsAdminSdk not implemented yet');
  @override
  HttpsFunctionsAdminSdk get https =>
      throw UnimplementedError('https not implemented yet');
  @override
  void registerAdminSdkFunction(
    String name,
    FirebaseFunctionAdminSdk function,
  ) {
    throw UnimplementedError('registerAdminSdkFunction');
  }*/
}

class _HttpsFunctionsAdminSdkHttp
    with HttpsFunctionsDefaultMixin
    implements HttpsFunctions {
  /*
  @override
  void onAdminSdkRequest(
    String name,
    RequestHandler handler, {
    FirebaseFunctionsAdminSdkHttpsOptions? httpsOptions,
  }) {*/
  // TODO: implement onAdminSdkRequest
}
