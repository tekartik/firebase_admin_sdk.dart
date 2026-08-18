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

  /// Get the server
  HttpServer get server => functions.httpServer;

  late final _serverUri = httpServerGetUri(functions.httpServer);

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

  @override
  late final client = httpFactory.client.newClient();

  /// Creates an HTTP test context.
  FirebaseFunctionsAdminSdkHttpTestContext({
    HttpFactory? httpFactory,
    required this.declarer,
    required this.app,
    this.signInInfo,
  }) : httpFactory = httpFactory ?? httpFactoryIo;
}
