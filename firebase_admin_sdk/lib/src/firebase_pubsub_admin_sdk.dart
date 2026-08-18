import 'dart:convert';
import 'dart:io';

import 'package:firebase_admin_sdk/firebase_admin_sdk.dart' as admin_sdk;
import 'package:googleapis/pubsub/v1.dart' as sdk;
import 'package:http/http.dart' as http;
import 'package:tekartik_firebase/firebase.dart';

import 'firebase_admin_sdk_common.dart';

/// The Pub/Sub emulator host (`PUBSUB_EMULATOR_HOST`), null when not running
/// against the emulator.
String? get pubsubEmulatorHost {
  var host = Platform.environment['PUBSUB_EMULATOR_HOST'];
  return (host?.isNotEmpty ?? false) ? host : null;
}

/// The Pub/Sub (topics) service for admin sdk.
FirebasePubsubServiceAdminSdk get firebasePubsubServiceAdminSdk =>
    _pubsubServiceAdminSdk ??= _FirebasePubsubServiceAdminSdk();

FirebasePubsubServiceAdminSdk? _pubsubServiceAdminSdk;

class _FirebasePubsubServiceAdminSdk implements FirebasePubsubServiceAdminSdk {
  @override
  FirebasePubsubTopicAdminSdk topic(FirebaseApp app, String topicName) {
    assert(app is FirebaseAppAdminSdk, 'invalid firebase app type');
    var adminApp = app as FirebaseAppAdminSdk;
    var sdkApp = (adminApp as dynamic).nativeInstance as admin_sdk.FirebaseApp;
    return _FirebasePubsubTopicAdminSdk(sdkApp, topicName);
  }
}

class _FirebasePubsubTopicAdminSdk implements FirebasePubsubTopicAdminSdk {
  final admin_sdk.FirebaseApp _app;
  @override
  final String name;

  _FirebasePubsubTopicAdminSdk(this._app, this.name);

  /// The api client, unauthenticated when running against the emulator.
  Future<sdk.PubsubApi> _api() async {
    var emulatorHost = pubsubEmulatorHost;
    if (emulatorHost != null) {
      return sdk.PubsubApi(http.Client(), rootUrl: 'http://$emulatorHost/');
    }
    return sdk.PubsubApi(await _app.client);
  }

  Future<String> _topicPath() async {
    var projectId =
        _app.projectId ??
        (throw StateError('No project id for app ${_app.name}'));
    return 'projects/$projectId/topics/$name';
  }

  @override
  Future<void> createIfNeeded() async {
    var api = await _api();
    var path = await _topicPath();
    try {
      await api.projects.topics.create(sdk.Topic(), path);
    } on sdk.DetailedApiRequestError catch (e) {
      // Already exists
      if (e.status != 409) {
        rethrow;
      }
    }
  }

  @override
  Future<String> publish(
    Map<String, Object?> data, {
    FirebasePubsubPublishOptions? options,
  }) => publishText(jsonEncode(data), options: options);

  @override
  Future<String> publishText(
    String text, {
    FirebasePubsubPublishOptions? options,
  }) => publishBytes(utf8.encode(text), options: options);

  @override
  Future<String> publishBytes(
    List<int> bytes, {
    FirebasePubsubPublishOptions? options,
  }) async {
    var api = await _api();
    var response = await api.projects.topics.publish(
      sdk.PublishRequest(
        messages: [
          sdk.PubsubMessage(
            data: base64Encode(bytes),
            attributes: options?.attributes,
            orderingKey: options?.orderingKey,
          ),
        ],
      ),
      await _topicPath(),
    );
    return response.messageIds!.first;
  }
}
