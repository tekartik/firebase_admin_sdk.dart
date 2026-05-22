import 'package:firebase_functions/firebase_functions.dart';

void main(List<String> args) {
  runFunctions((firebase) async {
    // Simulate some async initialization work
    await Future<void>.delayed(const Duration(seconds: 1));
    // https://firebase.google.com/docs/functions/http-events
    firebase.https.onRequest(
      name: 'hello-world',
      options: const HttpsOptions(
        cors: Cors(['*']),
        region: Region(SupportedRegion.europeWest1),
        timeoutSeconds: TimeoutSeconds(10),
        // Set maxInstances to control costs during unexpected traffic spikes.
        // https://firebase.google.com/docs/functions/manage-functions#min-max-instances
        maxInstances: Instances(11),
      ),
      (request) async => Response(200, body: 'Hello from Dart Functions!'),
    );
  });
}
