import 'dart:convert';
import 'dart:typed_data';

import 'package:firebase_functions/firebase_functions.dart' as fn;
import 'package:tekartik_common_utils/byte_utils.dart';
import 'package:tekartik_common_utils/json_utils.dart';
import 'package:tekartik_firebase/firebase_mixin.dart';
import 'package:tekartik_firebase_admin_sdk/firebase_admin_sdk.dart';
import 'package:tekartik_firebase_admin_sdk/mixin_admin_sdk.dart';
import 'package:tekartik_firebase_functions/firebase_functions.dart';
import 'package:tekartik_firebase_functions_http/firebase_functions_http_mixin.dart';

import 'import_http.dart';

/// Admin SDK specific HTTPS options.
typedef HttpOptionsAdminSdk = fn.HttpsOptions;

/// Admin SDK Firebase Functions service.
abstract class FirebaseFunctionsServiceAdminSdk
    implements FirebaseFunctionsService {
  /// Starts the Firebase Functions runtime.
  Future<void> fireUp(
    List<String> args,
    TekartikFirebaseFunctionsAdminSdkRunner runner,
  );
}

/// Admin SDK Firebase Functions instance.
abstract class FirebaseFunctionsAdminSdk implements FirebaseFunctions {}

/// Callback type for the Admin SDK function registration.
typedef TekartikFirebaseFunctionsAdminSdkRunner =
    Future<void> Function(FirebaseFunctionsAdminSdk functions);

class _FirebaseFunctionsServiceAdminSdk
    with
        FirebaseProductServiceMixin<FirebaseFunctions>,
        FirebaseFunctionsServiceDefaultMixin
    implements FirebaseFunctionsServiceAdminSdk {
  @override
  FirebaseFunctionsAdminSdk functions(FirebaseApp app) {
    throw UnimplementedError(
      'Use fireUp() for Admin SDK functions registration',
    );
  }

  @override
  Future<void> fireUp(
    List<String> args,
    TekartikFirebaseFunctionsAdminSdkRunner runner,
  ) async {
    await fn.fireUp(args, (rawFunctions) async {
      var ff = _FirebaseFunctionsAdminSdk(
        service: this,
        rawFunctions: rawFunctions,
      );
      await runner.call(ff);
    });
  }
}

class _ExpressHttpRequestAdminSdk implements ExpressHttpRequest {
  final fn.Request _rawRequest;

  late Uint8List bytes;
  late final ready = () async {
    bytes = await listStreamGetBytes(_rawRequest.read());
  }();
  _ExpressHttpRequestAdminSdk(this._rawRequest);

  @override
  Object? get body => bytes;

  String get bodyAsString => utf8.decode(bytes);

  Map<String, dynamic> get bodyAsJson => parseJsonObject(bodyAsString)!;

  @override
  late final headers = () {
    var headers = HttpHeadersMemory()..addMap(_rawRequest.headers);
    return headers;
  }();

  @override
  String get method => _rawRequest.method;

  @override
  Uri get requestedUri => _rawRequest.requestedUri;

  late final _response = _ExpressHttpResponseAdminSdk();

  @override
  ExpressHttpResponse get response => _response;

  @override
  Uri get uri => requestedUri;
}

class _ExpressHttpResponseAdminSdk implements ExpressHttpResponse {
  @override
  var statusCode = 200;
  late fn.Response response;

  _ExpressHttpResponseAdminSdk();

  @override
  Future<void> send([Object? body]) async {
    response = fn.Response(statusCode, body: body);
  }

  @override
  Future redirect(Uri location, {int? status = 302}) async {
    statusCode = status ?? 302;
  }

  @override
  late final headers = HttpHeadersMemory();

  @override
  Future<void> close() async {
    response = fn.Response(statusCode);
  }

  @override
  Future<void> write(Object? obj) =>
      throw UnsupportedError('write not supported');

  @override
  void add(Uint8List bytes) {
    // TODO: implement add
  }

  @override
  void writeln(String content) {
    // TODO: implement writeln
  }
}

class _FirebaseFunctionsAdminSdk
    with
        FirebaseAppProductMixin<FirebaseFunctions>,
        FirebaseFunctionsDefaultMixin
    implements FirebaseFunctionsAdminSdk {
  /// The underlying raw functions instance.
  final fn.Firebase rawFunctions;

  @override
  final _FirebaseFunctionsServiceAdminSdk service;

  _FirebaseFunctionsAdminSdk({
    required this.service,
    required this.rawFunctions,
  });

  @override
  late final app = firebaseAdminSdk.fromNativeApp(rawFunctions.adminApp);

  @override
  late final HttpsFunctions https = _HttpsAdminSdk(this);

  /// register a function
  @override
  void operator []=(String key, FirebaseFunction function) {
    registerFunction(key, function);
  }

  @override
  void registerFunction(String name, FirebaseFunction function) {
    var functionAdminSdk = function as FirebaseFunctionAdminSdk;
    functionAdminSdk.register(name);
  }
}

class _HttpsAdminSdk with HttpsFunctionsDefaultMixin implements HttpsFunctions {
  final _FirebaseFunctionsAdminSdk _functions;

  _HttpsAdminSdk(this._functions);

  @override
  HttpsFunction onRequest(
    RequestHandler handler, {
    HttpsOptions? httpsOptions,
  }) {
    return _HttpsFunctionAdminSdk(
      httpsAdminSdk: this,
      handler: handler,
      httpsOptions: httpsOptions,
    );
  }
}

/// Admin SDK Https function.
abstract class HttpsFunctionAdminSdk
    implements FirebaseFunctionAdminSdk, HttpsFunction {}

/// Firebase functions common
abstract class FirebaseFunctionAdminSdk implements FirebaseFunction {
  /// register
  void register(String name);
}

class _HttpsFunctionAdminSdk implements HttpsFunctionAdminSdk {
  final _HttpsAdminSdk httpsAdminSdk;
  final RequestHandler handler;
  final HttpsOptions? httpsOptions;

  _HttpsFunctionAdminSdk({
    required this.httpsAdminSdk,
    required this.handler,
    required this.httpsOptions,
  });

  @override
  void register(String name) {
    httpsAdminSdk._functions.rawFunctions.https.onRequest(
      (request) async {
        var express = _ExpressHttpRequestAdminSdk(request);
        await express.ready;
        await handler.call(express);
        return express._response.response;
      },
      // ignore: non_const_argument_for_const_parameter
      name: name, // Name mapping logic would go here
      // ignore: non_const_argument_for_const_parameter
      options: _wrapHttpsOptions(httpsOptions),
    );
  }

  fn.HttpsOptions? _wrapHttpsOptions(HttpsOptions? httpsOptions) {
    if (httpsOptions == null) {
      return null;
    }
    var cors = (httpsOptions.cors == true) ? const fn.Cors(['*']) : null;
    //var region = fireUp
    //region: fireUpRegionBelgium,
    // Set maxInstances to control costs during unexpected traffic spikes.
    // https://firebase.google.com/docs/functions/manage-functions#min-max-instances

    return fn.HttpsOptions(cors: cors);
  }
}

/// Global Admin SDK functions service.
final FirebaseFunctionsServiceAdminSdk firebaseFunctionsServiceAdminSdk =
    _firebaseFunctionsServiceAdminSdk;

final _firebaseFunctionsServiceAdminSdk = _FirebaseFunctionsServiceAdminSdk();
