import 'package:firebase_functions/firebase_functions.dart' as fn;
import 'package:tekartik_common_utils/common_utils_import.dart';
import 'package:tekartik_firebase/firebase_mixin.dart';
import 'package:tekartik_firebase_admin_sdk/firebase_admin_sdk.dart';
import 'package:tekartik_firebase_admin_sdk/firebase_auth_admin_sdk.dart';
import 'package:tekartik_firebase_admin_sdk/mixin_admin_sdk.dart';
//import 'package:tekartik_firebase_auth/src/auth.dart';
import 'package:tekartik_firebase_functions/firebase_functions.dart';
import 'package:tekartik_firebase_functions_http/firebase_functions_http_mixin.dart';

/// Callback type for the Admin SDK function registration.
typedef TekartikFirebaseFunctionsFireUpRunner =
    FutureOr<void> Function(FirebaseFunctions functions);

/// Admin SDK specific HTTPS options.
typedef HttpOptionsAdminSdk = fn.HttpsOptions;

/// Admin SDK Firebase Functions service.
abstract class FirebaseFunctionsServiceAdminSdk
    implements FirebaseFunctionsService {
  /// Starts the Firebase Functions runtime.
  Future<void> fireUp(TekartikFirebaseFunctionsAdminSdkRunner runner);
}

/// Admin SDK Firebase Functions instance.
abstract class FirebaseFunctionsAdminSdk implements FirebaseFunctions {}

/// Request handler
typedef FirebaseFunctionsAdminSdkRequestHandler =
    FutureOr<fn.Response> Function(
      FirebaseFunctions firebaseFunctions,
      fn.Request request,
    );

/// Call handler
typedef FirebaseFunctionsAdminSdkCallHandler<T extends Object> =
    Future<fn.CallableResult<T>> Function(
      FirebaseFunctions firebaseFunctions,
      fn.CallableRequest<Object?> request,
      fn.CallableResponse<T> response,
    );

/// Extension on native implementation
extension FirebaseFunctionsAdminSdkFirebaseExt on fn.Firebase {
  /// The abstracted firebase app;
  FirebaseApp get firebaseApp =>
      firebaseFunctionsServiceAdminSdk._impl.firebaseFunctionsAdminSdkApp ??=
          firebaseAdminSdk.fromNativeApp(adminApp);

  /// Https handler.
  Future<fn.Response> Function(fn.Request request) httpsHandler(
    FirebaseFunctionsAdminSdkRequestHandler handler,
  ) {
    return (request) async {
      var ff = _FirebaseFunctionsAdminSdk(
        service: firebaseFunctionsServiceAdminSdk._impl,
        rawFunctions: this,
      );
      return await handler.call(ff, request);
    };
  }

  /// Call handler.
  Future<fn.CallableResult<T>> Function(
    fn.CallableRequest<Object?> request,
    fn.CallableResponse<T> response,
  )
  callHandler<T extends Object>(
    FirebaseFunctionsAdminSdkCallHandler<T> handler,
  ) {
    return (request, response) async {
      var ff = _FirebaseFunctionsAdminSdk(
        service: firebaseFunctionsServiceAdminSdk._impl,
        rawFunctions: this,
      );
      return await handler.call(ff, request, response);
    };
  }
}

/// Admin SDK Https functions.
abstract class HttpsFunctionsAdminSdk implements HttpsFunctions {}

/// Callback type for the Admin SDK function registration.
typedef TekartikFirebaseFunctionsAdminSdkRunner =
    FutureOr<void> Function(FirebaseFunctionsAdminSdk functions);

class _FirebaseFunctionsServiceAdminSdk
    with
        FirebaseProductServiceMixin<FirebaseFunctions>,
        FirebaseFunctionsServiceDefaultMixin
    implements FirebaseFunctionsServiceAdminSdk {
  /// Global initialized once
  FirebaseApp? firebaseFunctionsAdminSdkApp;
  @override
  FirebaseFunctionsAdminSdk functions(FirebaseApp app) {
    throw UnimplementedError(
      'Use fireUp() for Admin SDK functions registration',
    );
  }

  @override
  Future<void> fireUp(TekartikFirebaseFunctionsAdminSdkRunner runner) async {
    await fn.runFunctions((rawFunctions) {
      var ff = _FirebaseFunctionsAdminSdk(
        service: this,
        rawFunctions: rawFunctions,
      );
      return runner.call(ff);
    });
  }
}

class _CallContextDecodedIdToken implements DecodedIdToken {
  @override
  final String uid;

  _CallContextDecodedIdToken({required this.uid});
}

class _CallContextAuthAdminSdk implements CallContextAuth {
  @override
  final _CallContextDecodedIdToken? token;

  _CallContextAuthAdminSdk({required this.token});

  @override
  String? get uid => token?.uid;
}

class _CallContextAdminSdk implements CallContext {
  @override
  final _CallContextAuthAdminSdk? auth;

  _CallContextAdminSdk({required this.auth});
}

class _CallRequestAdminSdk implements CallRequest {
  final fn.CallableRequest<Object?> request;
  final fn.CallableResponse<Object?> response;

  _CallRequestAdminSdk(this.request, this.response);
  @override
  late final context = () {
    var uid = request.instanceIdToken;
    _CallContextAuthAdminSdk? auth;
    if (uid != null) {
      auth = _CallContextAuthAdminSdk(
        token: _CallContextDecodedIdToken(uid: uid),
      );
    }
    var context = _CallContextAdminSdk(auth: auth);
    return context;
  }();

  @override
  Object? get data => request.data;

  @override
  // TODO: implement text
  String? get text {
    var data = this.data;
    if (data == null) {
      return null;
    }
    return jsonEncode(data);
  }
}

extension on FirebaseFunctionsAdminSdk {
  // ignore: unused_element
  _FirebaseFunctionsAdminSdk get _impl => this as _FirebaseFunctionsAdminSdk;
}

extension on FirebaseFunctionsServiceAdminSdk {
  _FirebaseFunctionsServiceAdminSdk get _impl =>
      this as _FirebaseFunctionsServiceAdminSdk;
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
  FirebaseApp get app => rawFunctions.firebaseApp;

  @override
  late final HttpsFunctionsAdminSdk https = _HttpsAdminSdk(this);

  /// register a function
  @override
  void operator []=(String key, FirebaseFunction function) {
    // ignore: non_const_argument_for_const_parameter
    registerFunction(key, function);
  }

  @override
  late final params = _ParamsAdminSdk(
    projectId: rawFunctions.adminApp.projectId!,
  );

  FirebaseFunctionsAdminSdkHttpsNamespace get httpsAdminSdk =>
      rawFunctions.https;
}

class _ParamsAdminSdk implements Params {
  @override
  final String projectId;

  _ParamsAdminSdk({required this.projectId});
}

class _HttpsAdminSdk
    with HttpsFunctionsDefaultMixin
    implements HttpsFunctionsAdminSdk {
  final _FirebaseFunctionsAdminSdk _functions;

  _HttpsAdminSdk(this._functions);

  @override
  HttpsCallableFunction onCall(
    CallHandler handler, {
    HttpsCallableOptions? callableOptions,
  }) {
    return _HttpsCallableFunctionAdminSdk(
      httpsAdminSdk: this,
      handler: handler,
      callableOptions: callableOptions,
    );
  }

  @override
  HttpsFunction onRequest(
    RequestHandler handler, {
    HttpsOptions? httpsOptions,
  }) {
    return _HttpsFunctionAdminSdk(
      httpsAdminSdk: this,
      handler: handler,
      httpsOptions: httpsOptions,
      fnHttpsOptions: null,
    );
  }
}

/// Admin SDK Https function.
abstract class HttpsFunctionAdminSdk
    implements FirebaseFunctionAdminSdk, HttpsFunction {}

/// Admin SDK Https callable function.
abstract class HttpsCallableFunctionAdminSdk
    implements FirebaseFunctionAdminSdk, HttpsCallableFunction {}

/// Firebase functions common
abstract class FirebaseFunctionAdminSdk implements FirebaseFunction {
  /// register
  void register(String name);
}

class _HttpsCallableFunctionAdminSdk implements HttpsCallableFunctionAdminSdk {
  final _HttpsAdminSdk httpsAdminSdk;
  final CallHandler handler;
  final HttpsCallableOptions? callableOptions;

  _HttpsCallableFunctionAdminSdk({
    required this.httpsAdminSdk,
    required this.handler,
    required this.callableOptions,
  });

  @override
  void register(String name) {
    httpsAdminSdk._functions.rawFunctions.https.onCall<Object>(
      (request, response) async {
        var callRequest = _CallRequestAdminSdk(request, response);
        var result = await handler.call(callRequest);
        return fn.CallableResult<Object>(result as Object);
      },
      // ignore: non_const_argument_for_const_parameter
      name: name,
      // ignore: non_const_argument_for_const_parameter
      options: _wrapCallableOptions(callableOptions),
    );
  }

  fn.CallableOptions? _wrapCallableOptions(
    HttpsCallableOptions? callableOptions,
  ) {
    if (callableOptions == null) {
      return null;
    }
    var globalOptions = wrapGlobalOptions(callableOptions);
    var fnCors = wrapCors(callableOptions.cors);
    return fn.CallableOptions(
      cors: fnCors,
      region: globalOptions.region,
      maxInstances: globalOptions.maxInstances,
      timeoutSeconds: globalOptions.timeoutSeconds,
    );
  }
}

class _HttpsFunctionAdminSdk implements HttpsFunctionAdminSdk {
  final _HttpsAdminSdk httpsAdminSdk;
  final RequestHandler handler;
  final FirebaseFunctionsAdminSdkHttpsOptions? fnHttpsOptions;
  final HttpsOptions? httpsOptions;

  _HttpsFunctionAdminSdk({
    required this.httpsAdminSdk,
    required this.handler,
    required this.httpsOptions,
    // ignore: experimental_member_use
    @mustBeConst required this.fnHttpsOptions,
  });

  @override
  void register(String name) {
    throw UnsupportedError(
      'user runFunctions with onRequest for Admin SDK functions registration',
    );
  }
}

/// Wrap the region as a string to a supported region
fn.Region? wrapRegion(String? region) {
  if (region == null) {
    return null;
  }
  var fnRegion = fn.Region(
    fn.SupportedRegion.values.firstWhere(
      (r) => r.value == region,
      orElse: () => throw ArgumentError('Unsupported region: $region'),
    ),
  );
  return fnRegion;
}

//fn.GlobalOptsion
/// Wrap instances
fn.Instances? wrapInstances(int? count) {
  if (count == null) {
    return null;
  }
  return fn.Instances(count);
}

/// Wrap global options
fn.GlobalOptions wrapGlobalOptions(GlobalOptions options) {
  var fnRegion = wrapRegion(options.region);
  var fnMaxInstances = wrapInstances(options.maxInstances);
  var fnTimeoutSeconds = wrapTimeoutSeconds(options.timeoutSeconds);
  return fn.GlobalOptions(
    region: fnRegion,
    maxInstances: fnMaxInstances,
    timeoutSeconds: fnTimeoutSeconds,
  );
}

/// Wrap cors
fn.Cors? wrapCors(bool? cors) {
  if (cors == null) {
    return null;
  }
  if (cors) {
    return const fn.Cors(['*']);
  }
  return null;
}

/// Wrap timeout
fn.TimeoutSeconds? wrapTimeoutSeconds(int? seconds) {
  if (seconds == null) {
    return null;
  }
  return fn.TimeoutSeconds(seconds);
}

/// Global Admin SDK functions service.
final FirebaseFunctionsServiceAdminSdk firebaseFunctionsServiceAdminSdk =
    _firebaseFunctionsServiceAdminSdk;

final _firebaseFunctionsServiceAdminSdk = _FirebaseFunctionsServiceAdminSdk();

/// Native Https options
typedef FirebaseFunctionsAdminSdkHttpsOptions = fn.HttpsOptions;

/// Native Region
typedef FirebaseFunctionsAdminSdkRegion = fn.Region;

/// Native SupportedRegion
typedef FirebaseFunctionsAdminSdkSupportedRegion = fn.SupportedRegion;

/// Native Cors
typedef FirebaseFunctionsAdminSdkCors = fn.Cors;

/// Native Instance
typedef FirebaseFunctionsAdminSdkInstances = fn.Instances;

/// Native https namespace
typedef FirebaseFunctionsAdminSdkHttpsNamespace = fn.HttpsNamespace;

/// Native TimeoutSeconds
typedef FirebaseFunctionsAdminSdkTimeoutSeconds = fn.TimeoutSeconds;

/// Native response
typedef FirebaseFunctionsAdminSdkResponse = fn.Response;
