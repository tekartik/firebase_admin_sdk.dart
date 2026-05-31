import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:path/path.dart';
import 'package:tekartik_common_utils/byte_utils.dart';
import 'package:tekartik_firebase/firebase_mixin.dart';
import 'package:tekartik_firebase_functions_admin_sdk/functions_admin_sdk.dart';
import 'package:tekartik_firebase_functions_http/firebase_functions_http.dart';
import 'package:tekartik_http/http.dart';
import 'package:tekartik_http/http_memory.dart';

/// Callback type for the Admin SDK HTTP function registration.
typedef TekartikFirebaseFunctionsAdminSdkHttpRunner =
    FutureOr<void> Function(FirebaseFunctionsAdminSdkHttp functions);

/// Firebase Functions service for local HTTP-based Admin SDK simulation.
abstract class FirebaseFunctionsServiceAdminSdkHttp
    implements FirebaseFunctionsService {
  /// Creates a local HTTP-based Firebase Functions service for Admin SDK simulation.
  factory FirebaseFunctionsServiceAdminSdkHttp({
    HttpServerFactory? httpServerFactory,
  }) => _FirebaseFunctionsServiceAdminSdkHttp(
    httpServerFactory: httpServerFactory,
  );

  /// Starts an HTTP server and calls [runner] to register functions on it.
  Future<void> fireUp(
    FirebaseApp app,
    TekartikFirebaseFunctionsAdminSdkHttpRunner runner,
  );
}

/// Default local HTTP-based Firebase Functions service for Admin SDK simulation.
final firebaseAdminServiceAdminSdkHttp = FirebaseFunctionsServiceAdminSdkHttp();

/// Firebase Functions instance backed by a local HTTP server.
abstract class FirebaseFunctionsAdminSdkHttp
    implements FirebaseFunctionsAdminSdk {
  @override
  HttpsFunctionsAdminSdkHttp get https;

  /// The underlying HTTP server.
  HttpServer get httpServer;
}

/// HTTPS functions interface for Admin SDK.
abstract class HttpsFunctionsAdminSdkHttp implements HttpsFunctions {
  /// Registers an Admin SDK request handler.
  void onAdminSdkRequest(
    String name,
    FirebaseFunctionsAdminSdkRequestHandler handler,
  );

  /// Registers an Admin SDK request handler.
  void onAdminSdkCall<T extends Object>(
    String name,
    FirebaseFunctionsAdminSdkCallHandler<T> handler,
  );
}

class _FirebaseFunctionsAdminSdkHttp
    with
        FirebaseFunctionsDefaultMixin,
        FirebaseAppProductMixin<FirebaseFunctions>
    implements FirebaseFunctionsAdminSdkHttp {
  final HttpServerFactory httpServerFactory;

  @override
  final FirebaseFunctionsServiceAdminSdkHttp service;

  @override
  final FirebaseApp app;

  _FirebaseFunctionsAdminSdkHttp({
    required this.service,
    required this.app,
    required this.httpServerFactory,
  });

  @override
  late HttpServer httpServer;
  final _functions = <String, _HttpsBase>{};

  @override
  late final HttpsFunctionsAdminSdkHttp https = _HttpsFunctionsAdminSdkHttp(
    functions: this,
  );

  Future<HttpServer> serveHttp({int? port}) async {
    port ??= firebaseFunctionsHttpDefaultPort;
    var requestServer = await httpServerFactory.bind(
      InternetAddress.anyIPv4,
      port,
    );
    for (final key in _functions.keys) {
      // ignore: avoid_print
      print('$key http://localhost:$port/$key');
    }

    // ignore: avoid_print
    print('listening on http://localhost:${requestServer.port}');

    // Launch in background
    unawaited(
      Future.sync(() async {
        await for (HttpRequest request in requestServer) {
          var uri = request.uri;
          //var handled = false;
          // /test
          var functionKey = uri.pathSegments.firstOrNull;
          try {
            if (functionKey == null) {
              // ignore: avoid_print
              print('No functions key found for $uri');
            } else {
              var function = _functions[functionKey];
              if (function is _HttpsFunction) {
                var method = request.method;

                // expect an absolute uri, ending with /
                var pathSegments = List.of(uri.pathSegments);
                var path =
                    '/${url.joinAll(pathSegments)}${pathSegments.length == 1 ? '/' : ''}';

                final rewrittenUri = request.requestedUri.replace(path: path);
                var hasBody = false;
                var body = Uint8List(0);
                if (request.contentLength != 0 &&
                    request.contentLength != null) {
                  hasBody = true;
                  body = await httpStreamGetBytes(request);
                }
                var adminSdkRequest = Request(
                  method,
                  rewrittenUri,
                  protocolVersion: '1.1',
                  headers: request.headers.toMap(),
                  body: hasBody ? body : null,
                );
                var adminSdkResponse = await function.handler(
                  this,
                  adminSdkRequest,
                );
                request.response.statusCode = adminSdkResponse.statusCode;
                adminSdkResponse.headers.forEach((name, value) {
                  request.response.headers.set(name, value);
                });
                if ((adminSdkResponse.contentLength ?? 0) > 0) {
                  var bodyBytes = await listStreamGetBytes(
                    adminSdkResponse.read(),
                  );
                  request.response.add(bodyBytes);
                }
                await request.response.close();
              } else if (function is _HttpsCall) {
                var body = await httpStreamGetBytes(request);
                var json = jsonDecode(utf8.decode(body)) as Map;
                var data = json['data'];

                var callableRequest = CallableRequest(
                  Request(
                    request.method,
                    request.requestedUri,
                    headers: request.headers.toMap(),
                  ),
                  data,
                  null,
                );
                var callableResponse = CallableResponse<Object>(
                  acceptsStreaming: false,
                );

                var result = await function.handler(
                  this,
                  callableRequest,
                  callableResponse,
                );

                request.response.statusCode = 200;
                request.response.headers.set(
                  'Content-Type',
                  'application/json; charset=utf-8',
                );
                request.response.write(jsonEncode({'result': result.data}));
                await request.response.close();
              }
              /*
            if (function is HttpsFunctionHttp) {
              final rewrittenUri = Uri(
                pathSegments: uri.pathSegments.sublist(1),
                query: uri.query,
                fragment: uri.fragment,
              );
              //io.HttpRequest commonRequest = new io.HttpRequest(request, url, request.uri.path);
              ExpressHttpRequest httpRequest = await asExpressHttpRequestHttp(
                request,
                rewrittenUri,
              );
              // cors?
              var cors = function.options?.cors ?? false;
              if (cors) {
                httpRequest.response.headers
                  ..set('Access-Control-Allow-Origin', '*')
                  ..set('Access-Control-Allow-Methods', 'POST, OPTIONS, GET');
                var requestHeaders =
                    request.headers['Access-Control-Request-Headers'];
                if (requestHeaders != null) {
                  httpRequest.response.headers.set(
                    'Access-Control-Allow-Headers',
                    requestHeaders,
                  );
                }
              }

              function.handler(httpRequest);
              handled = true;
            }

             */
            }
          } catch (e) {
            try {
              request.response.statusCode = 500;
            } catch (_) {}
            try {
              request.response.write('Error: $e');
            } catch (_) {}
            await request.response.close();
          }
        }
      }),
    );
    httpServer = requestServer;
    return requestServer;
  }
}

abstract class _HttpsBase {
  final String name;

  _HttpsBase({required this.name});
}

class _HttpsFunction extends _HttpsBase {
  final FirebaseFunctionsAdminSdkRequestHandler handler;

  _HttpsFunction({required super.name, required this.handler});
}

class _HttpsCall extends _HttpsBase {
  final FirebaseFunctionsAdminSdkCallHandler<Object> handler;

  _HttpsCall({required super.name, required this.handler});
}

class _HttpsFunctionsAdminSdkHttp
    with HttpsFunctionsDefaultMixin
    implements HttpsFunctionsAdminSdkHttp {
  final _FirebaseFunctionsAdminSdkHttp functions;

  _HttpsFunctionsAdminSdkHttp({required this.functions});

  @override
  void onAdminSdkRequest(
    String name,
    FirebaseFunctionsAdminSdkRequestHandler handler,
  ) {
    functions._functions[name] = _HttpsFunction(name: name, handler: handler);
  }

  @override
  void onAdminSdkCall<T extends Object>(
    String name,
    FirebaseFunctionsAdminSdkCallHandler<T> handler,
  ) {
    functions._functions[name] = _HttpsCall(
      name: name,
      handler: (ff, request, response) async {
        var typedResponse = CallableResponse<T>(
          acceptsStreaming: response.acceptsStreaming,
          heartbeatSeconds: response.heartbeatSeconds,
        );
        return await handler(ff, request, typedResponse);
      },
    );
  }
}

class _FirebaseFunctionsServiceAdminSdkHttp
    with
        FirebaseProductServiceMixin<FirebaseFunctions>,
        FirebaseFunctionsServiceDefaultMixin
    implements FirebaseFunctionsServiceAdminSdkHttp {
  final HttpServerFactory _httpServerFactory;

  _FirebaseFunctionsServiceAdminSdkHttp({HttpServerFactory? httpServerFactory})
    : _httpServerFactory = httpServerFactory ?? httpServerFactoryMemory;

  @override
  Future<void> fireUp(
    FirebaseApp app,
    TekartikFirebaseFunctionsAdminSdkHttpRunner runner,
  ) async {
    var ff = _FirebaseFunctionsAdminSdkHttp(
      service: this,
      app: app,
      httpServerFactory: _httpServerFactory,
    );
    await runner(ff);
    await ff.serveHttp();
  }
}

/// Create a Firebase Functions Admin SDK HTTP service.
///
/// Uses an in-memory HTTP server by default (suitable for tests).
/// Pass a custom [httpServerFactory] to use a real IO server.
FirebaseFunctionsServiceAdminSdkHttp newFirebaseFunctionsServiceAdminSdkHttp({
  HttpServerFactory? httpServerFactory,
}) =>
    _FirebaseFunctionsServiceAdminSdkHttp(httpServerFactory: httpServerFactory);
