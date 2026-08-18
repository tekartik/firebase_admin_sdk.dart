# Pub/Sub functions

A pub/sub function (`onMessagePublished`) is triggered by a message published
on a topic. The deployed function name is derived from the topic
(`onmessagepublished-<topic without hyphens>`), it is not chosen by the user.

## Handling a message

The handler is a `FirebaseFunctionsAdminSdkPubsubHandler`:

```dart
Future<void> myPubsubHandler(
  FirebaseFunctions firebaseFunctions,
  CloudEvent<PubsubMessage> event,
) async {
  var message = event.data!;
  print('data: ${message.jsonData}, attributes: ${message.attributes}');
}
```

Deployed (or emulated) functions are declared in `bin/server.dart`, the topic
and the options must be constants so that the `package:firebase_functions`
builder can generate `functions.yaml`:

```dart
runFunctions((firebase) {
  // ignore: experimental_member_use
  firebase.pubsub.onMessagePublished(
    firebase.pubsubHandler(myPubsubHandler),
    topic: 'my-topic',
    options: const PubSubOptions(region: Region(SupportedRegion.europeWest1)),
  );
});
```

Locally (`tekartik_firebase_functions_admin_sdk_http`), the same handler is
registered on the local http server, which simulates a Pub/Sub delivery (a
`POST` with the cloud event json body Pub/Sub sends):

```dart
functions.pubsub.onAdminSdkMessagePublished(
  'my-pubsub-fn',
  topic: 'my-topic',
  handler: myPubsubHandler,
);
```

`functions.pubsub.functionNameForTopic('my-topic')` gives back the local
function name, i.e. the path the message must be posted to.
`pubsubMessagePublishedCloudEventJson()` builds the body.

## Publishing a message

Publishing uses the admin sdk (see `tekartik_firebase_admin_sdk`), from a
server or from another function:

```dart
var topic = firebasePubsubServiceAdminSdk.topic(app, 'my-topic');
await topic.publish({'my': 'data'});
```

`publishText`, `publishBytes` and `createIfNeeded` are also available.

### Emulator

The `pubsub` emulator must be started along with the `functions` emulator
(`"pubsub": {"port": 8085}` in `firebase.json`, and `onlyPubsub: true` in the
`FirebaseEmulatorOptions` when using `--only`). The functions emulator then
creates the topic and its subscription, and `PUBSUB_EMULATOR_HOST` is set for
the emulated functions, so a function publishing a message targets the
emulator (the Pub/Sub emulator supports the REST api used here).
