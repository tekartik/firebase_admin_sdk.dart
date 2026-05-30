import 'package:tekartik_firebase_functions_admin_sdk/functions_admin_sdk.dart';
import 'package:tekartik_firebase_functions_admin_sdk_test/functions.dart';

void main(List<String> args) {
  runFunctions((firebase) {
    // https://firebase.google.com/docs/functions/http-events
    firebase.https.onRequest(
      name: testFunctionHttpsV1,
      options: const HttpsOptions(
        cors: Cors(['*']),
        // Set maxInstances to control costs during unexpected traffic spikes.
        // https://firebase.google.com/docs/functions/manage-functions#min-max-instances
        maxInstances: Instances(11),
        region: Region(SupportedRegion.europeWest1),
        timeoutSeconds: TimeoutSeconds(19),
      ),
      firebase.httpsHandler(functionsHttpV1Handler),
    );
  });
}
