import 'dart:async';
import 'dart:convert';

import 'package:path/path.dart';
import 'package:tekartik_firebase_functions_admin_sdk/functions_admin_sdk.dart';
import 'package:tekartik_firebase_functions_admin_sdk_http/functions_admin_sdk_http.dart';
import 'package:tekartik_firebase_functions_admin_sdk_test/test_context.dart';
import 'package:tekartik_firebase_functions_call/functions_call.dart';
import 'package:tekartik_http_io/http_io.dart';

/// HTTP test context for Firebase Functions Admin SDK.
class FirebaseFunctionsAdminSdkHttpTestContext
    implements FirebaseFunctionsAdminSdkTestContext {
  @override
  final FirebaseFunctionsAdminSdkTestContextSignInInfo? signInInfo;
  var _refCount = 0;

  /// The HTTP factory.
  final HttpFactory httpFactory;

  /// The runner function to declare functions.
  final TekartikFirebaseFunctionsAdminSdkHttpRunner declarer;

  /// The Firebase application.
  final FirebaseApp app;

  /// The Firebase functions admin SDK instance.
  late FirebaseFunctionsAdminSdkHttp functions;

  /// Starts the server on the first call, on any free port (the uri is read
  /// back from the server): a fixed one would fail when another server, or
  /// another context, uses it.
  @override
  Future<void> setUpAll() async {
    if (_refCount++ == 0) {
      var service = FirebaseFunctionsServiceAdminSdkHttp(
        httpServerFactory: httpFactory.server,
        port: 0,
      );
      await service.fireUp(app, (functions) async {
        this.functions = functions;

        await declarer(functions);
      });
      _serverUri = httpServerGetUri(functions.httpServer);
      _client = httpFactory.client.newClient();
    }
  }

  /// Closes the client and the server on the last call; a later [setUpAll]
  /// starts them again.
  @override
  Future<void> tearDownAll() async {
    if (--_refCount == 0) {
      _client?.close();
      _client = null;
      await functions.httpServer.close(force: true);
    }
  }

  /// Get the server
  HttpServer get server => functions.httpServer;

  late Uri _serverUri;

  @override
  Uri httpsUri(String path) =>
      _serverUri.replace(path: url.join(_serverUri.path, path));

  /// Simulates a Pub/Sub delivery on the local http server.
  @override
  Future<void> publishMessage(String topic, Map<String, Object?> data) async {
    var name = functions.pubsub.functionNameForTopic(topic);
    var uri = httpsUri(name);
    var body = pubsubMessagePublishedCloudEventJson(
      projectId: app.projectId,
      topic: topic,
      data: base64Encode(utf8.encode(jsonEncode(data))),
      messageId: '${++_lastMessageId}',
    );
    var response = await httpClientSend(
      client,
      httpMethodPost,
      uri,
      headers: (HttpHeaders()..mimeType = httpContentTypeJson).toStringMap(),
      body: jsonEncode(body),
    );
    if (response.statusCode != httpStatusCodeOk) {
      throw StateError(
        'Publish message failed ${response.statusCode} ${response.body}',
      );
    }
  }

  var _lastMessageId = 0;

  /// Simulates a Cloud Tasks delivery on the local http server.
  @override
  Future<void> enqueueTask(
    String functionName,
    Map<String, Object?> data,
  ) async {
    var uri = httpsUri(functionName);
    var response = await httpClientSend(
      client,
      httpMethodPost,
      uri,
      headers: (HttpHeaders()..mimeType = httpContentTypeJson).toStringMap(),
      body: jsonEncode({'data': data}),
    );
    if (response.statusCode != taskDispatchedNoContentStatusCode) {
      throw StateError(
        'Enqueue task failed ${response.statusCode} ${response.body}',
      );
    }
  }

  Client? _client;

  /// The client of the current setup, closed by the last [tearDownAll].
  @override
  Client get client =>
      _client ?? (throw StateError('setUpAll not called or torn down'));

  /// Creates an HTTP test context.
  FirebaseFunctionsAdminSdkHttpTestContext({
    HttpFactory? httpFactory,
    required this.declarer,
    required this.app,
    this.signInInfo,
  }) : httpFactory = httpFactory ?? httpFactoryIo;
}
