import 'package:tekartik_firebase_admin_sdk/firebase_auth_admin_sdk.dart';
import 'package:tekartik_firebase_functions_admin_sdk/functions_admin_sdk.dart';
import 'package:tekartik_firebase_functions_admin_sdk_test/functions.dart';

void main(List<String> args) {
  testFunctionsInitBuilders();

  runFunctions((firebase) {
    // Init needed services
    var app = firebase.firebaseApp;
    firebaseAuthServiceAdminSdk.auth(app);

    // https://firebase.google.com/docs/functions/http-events
    firebase.https.onRequest(
      firebase.httpsHandler(functionsHttpV1Handler),
      name: testDartFunctionHttpsV1,
      options: const HttpsOptions(
        cors: Cors(['*']),
        // Set maxInstances to control costs during unexpected traffic spikes.
        // https://firebase.google.com/docs/functions/manage-functions#min-max-instances
        maxInstances: Instances(11),
        region: Region(SupportedRegion.europeWest1),
        timeoutSeconds: TimeoutSeconds(19),
      ),
    );
    firebase.https.onCall(
      firebase.callHandler(functionsCallV1Handler),
      name: testDartFunctionCallV1,
      options: const CallableOptions(
        cors: Cors(['*']),
        region: Region(SupportedRegion.europeWest1),
      ),
    );
    firebase.https.onCall(
      firebase.callHandler(callBasicAdminSdkHandler),
      name: 'adminsdkbasic',
      options: const CallableOptions(
        cors: Cors(['*']),
        region: Region(SupportedRegion.europeWest1),
      ),
    );
  });
}
