import 'package:firebase_functions/firebase_functions.dart';

void main(List<String> args) {
  runFunctions((firebase) {
    // https://firebase.google.com/docs/functions/http-events
    firebase.https.onRequest(
      name: 'hello-world',
      options: const HttpsOptions(
        cors: Cors(['*']),
        // Set maxInstances to control costs during unexpected traffic spikes.
        // https://firebase.google.com/docs/functions/manage-functions#min-max-instances
        maxInstances: Instances(10),
        region: Region(SupportedRegion.europeWest1),
      ),
      (request) async => Response(200, body: 'Hello 2 from Dart Functions!'),
    );
  });
}
