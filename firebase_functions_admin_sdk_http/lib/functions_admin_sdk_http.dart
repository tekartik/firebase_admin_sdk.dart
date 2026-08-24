import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:path/path.dart';
import 'package:tekartik_common_utils/byte_utils.dart';
import 'package:tekartik_common_utils/int_utils.dart';
import 'package:tekartik_firebase/firebase.dart';
import 'package:tekartik_firebase/firebase_mixin.dart';
import 'package:tekartik_firebase_functions/firebase_functions.dart'
    show
        HttpsFunctions,
        FirebaseFunctionsDefaultMixin,
        HttpsFunctionsDefaultMixin,
        FirebaseFunctionsServiceDefaultMixin;
import 'package:tekartik_firebase_functions/firebase_functions.dart' as ff;
import 'package:tekartik_firebase_functions_admin_sdk/functions_admin_sdk.dart';
import 'package:tekartik_firebase_functions_http/firebase_functions_http.dart'
    show firebaseFunctionsHttpDefaultPort;
import 'package:tekartik_firebase_functions_http/firebase_functions_http_mixin.dart'
    show firebaseFunctionsHttpHeaderUid;
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

  @override
  TasksFunctionsAdminSdkHttp get tasks;

  @override
  PubsubFunctionsAdminSdkHttp get pubsub;

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

/// Tasks functions interface for Admin SDK.
///
/// A task dispatched function is simulated as a callable-like function: a
/// `POST` on the function url with a `{'data': ...}` json body (i.e. exactly
/// what Cloud Tasks delivers) triggers the handler and responds with a
/// `204 No Content` (or a `500` if the handler fails).
abstract class TasksFunctionsAdminSdkHttp implements TasksFunctionsAdminSdk {
  /// Registers an Admin SDK task dispatched handler.
  void onAdminSdkTaskDispatched(
    String name,
    FirebaseFunctionsAdminSdkTaskHandler handler,
  );
}

/// Pub/Sub functions interface for Admin SDK.
///
/// A pub/sub triggered function is simulated as an http function: a `POST` on
/// the function url with a cloud event json body (i.e. exactly what Pub/Sub
/// delivers, see [pubsubMessagePublishedCloudEventJson]) triggers the handler.
abstract class PubsubFunctionsAdminSdkHttp implements PubsubFunctionsAdminSdk {
  /// Registers an Admin SDK message published handler on [topic].
  void onAdminSdkMessagePublished(
    String name, {
    required String topic,
    required FirebaseFunctionsAdminSdkPubsubHandler handler,
  });

  /// The name of the local function registered for [topic].
  ///
  /// Throws a [StateError] if no function is registered for [topic].
  String functionNameForTopic(String topic);
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
  var _lastTaskId = 0;

  @override
  late final HttpsFunctionsAdminSdkHttp https = _HttpsFunctionsAdminSdkHttp(
    functions: this,
  );

  @override
  late final TasksFunctionsAdminSdkHttp tasks = _TasksFunctionsAdminSdkHttp(
    functions: this,
  );

  @override
  late final PubsubFunctionsAdminSdkHttp pubsub = _PubsubFunctionsAdminSdkHttp(
    functions: this,
  );

  @override
  late final TasksFunctionsAdminSdkHttp tasks = _TasksFunctionsAdminSdkHttp(
    functions: this,
  );

  @override
  late final PubsubFunctionsAdminSdkHttp pubsub = _PubsubFunctionsAdminSdkHttp(
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
                var userId = request.headers.value(
                  firebaseFunctionsHttpHeaderUid,
                );
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
                  auth: userId == null ? null : AuthData(uid: userId),
                );
                var callableResponse = CallableResponse<Object>(
                  acceptsStreaming: false,
                );

                Future<void> sendError(
                  HttpResponse response,
                  HttpResponseException error,
                ) async {
                  response.statusCode = error.statusCode;
                  response.headers.set(
                    'Content-Type',
                    'application/json; charset=utf-8',
                  );
                  response.write(jsonEncode(error.toJson()));
                  await response.close();
                }

                try {
                  var result = await function.handler(
                    this,
                    callableRequest,
                    callableResponse,
                  );

                  var response = result.toResponse();
                  request.response.statusCode = response.statusCode;
                  response.headers.forEach((name, value) {
                    request.response.headers.set(name, value);
                  });

                  request.response.write(await response.readAsString());
                  await request.response.close();
                } on HttpResponseException catch (e) {
                  var response = request.response;

                  await sendError(response, e);
                } catch (e) {
                  var httpsError = HttpResponseException.internalServerError(
                    message: 'Internal error',
                    details: [
                      {'exception': '$e'},
                    ],
                  );
                  var response = request.response;

                  await sendError(response, httpsError);
                }
                /*
                  request.response.statusCode = e.code;
                  request.response.headers.set(
                    'Content-Type',
                    'application/json; charset=utf-8',
                  );
                  request.response.write(
                    jsonEncode({
                      'error': {
                        'code': e.code,
                        'message': e.message,
                        'details': e.details,
                      },
                    }),
                  );
                  await request.response.close();
                  return;
                }*/
              } else if (function is _HttpsTask) {
                var headers = request.headers;
                var userId = headers.value(firebaseFunctionsHttpHeaderUid);
                var bodyBytes = await httpStreamGetBytes(request);
                Object? data;
                if (bodyBytes.isNotEmpty) {
                  var json = jsonDecode(utf8.decode(bodyBytes));
                  if (json is Map) {
                    data = json['data'];
                  }
                }
                var taskRequest = TaskRequest<Object?>(
                  Request(
                    request.method,
                    request.requestedUri,
                    headers: headers.toMap(),
                  ),
                  data,
                  queueName:
                      headers.value(cloudTasksHeaderQueueName) ?? function.name,
                  id:
                      headers.value(cloudTasksHeaderTaskName) ??
                      '${++_lastTaskId}',
                  retryCount:
                      parseInt(headers.value(cloudTasksHeaderTaskRetryCount)) ??
                      0,
                  executionCount:
                      parseInt(
                        headers.value(cloudTasksHeaderTaskExecutionCount),
                      ) ??
                      0,
                  scheduledTime:
                      headers.value(cloudTasksHeaderTaskEta) ??
                      DateTime.now().toUtc().toIso8601String(),
                  previousResponse: parseInt(
                    headers.value(cloudTasksHeaderTaskPreviousResponse),
                  ),
                  retryReason: headers.value(cloudTasksHeaderTaskRetryReason),
                  auth: userId == null ? null : TaskAuthData(uid: userId),
                );
                try {
                  await function.handler(this, taskRequest);
                  // No content, as done by the native implementation.
                  request.response.statusCode =
                      taskDispatchedNoContentStatusCode;
                  await request.response.close();
                } catch (e) {
                  await _sendInternalError(request, e);
                }
              } else if (function is _HttpsPubsub) {
                var bodyBytes = await httpStreamGetBytes(request);
                var json =
                    jsonDecode(utf8.decode(bodyBytes)) as Map<String, Object?>;
                var event = CloudEvent<PubsubMessage>.fromJson(
                  json.cast<String, dynamic>(),
                  PubsubMessage.fromJson,
                );
                try {
                  await function.handler(this, event);
                  request.response.statusCode = httpStatusCodeOk;
                  await request.response.close();
                } catch (e) {
                  await _sendInternalError(request, e);
                }
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

Future<void> _sendInternalError(HttpRequest request, Object e) async {
  var error = HttpResponseException.internalServerError(
    message: 'INTERNAL',
    details: [
      {'exception': '$e'},
    ],
  );
  var response = request.response;
  response.statusCode = error.statusCode;
  response.headers.set('Content-Type', 'application/json; charset=utf-8');
  response.write(jsonEncode(error.toJson()));
  await response.close();
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

class _HttpsTask extends _HttpsBase {
  final FirebaseFunctionsAdminSdkTaskHandler handler;

  _HttpsTask({required super.name, required this.handler});
}

class _HttpsPubsub extends _HttpsBase {
  final FirebaseFunctionsAdminSdkPubsubHandler handler;
  final String topic;

  _HttpsPubsub({
    required super.name,
    required this.topic,
    required this.handler,
  });
}

class _PubsubFunctionsAdminSdkHttp
    with PubsubFunctionsAdminSdkDefaultMixin
    implements PubsubFunctionsAdminSdkHttp {
  final _FirebaseFunctionsAdminSdkHttp functions;

  _PubsubFunctionsAdminSdkHttp({required this.functions});

  @override
  void onAdminSdkMessagePublished(
    String name, {
    required String topic,
    required FirebaseFunctionsAdminSdkPubsubHandler handler,
  }) {
    functions._functions[name] = _HttpsPubsub(
      name: name,
      topic: topic,
      handler: handler,
    );
  }

  @override
  String functionNameForTopic(String topic) {
    for (var function in functions._functions.values) {
      if (function is _HttpsPubsub && function.topic == topic) {
        return function.name;
      }
    }
    throw StateError('No pub/sub function registered for topic $topic');
  }
}

class _TasksFunctionsAdminSdkHttp
    with TasksFunctionsAdminSdkDefaultMixin
    implements TasksFunctionsAdminSdkHttp {
  final _FirebaseFunctionsAdminSdkHttp functions;

  _TasksFunctionsAdminSdkHttp({required this.functions});

  @override
  void onAdminSdkTaskDispatched(
    String name,
    FirebaseFunctionsAdminSdkTaskHandler handler,
  ) {
    functions._functions[name] = _HttpsTask(name: name, handler: handler);
  }
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
