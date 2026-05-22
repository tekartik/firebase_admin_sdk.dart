import 'package:tekartik_firebase_functions_admin_sdk/functions_admin_sdk.dart';

void main(List<String> args) {
  var service = firebaseFunctionsServiceAdminSdk;
  service.fireUp((functions) {
    // https://firebase.google.com/docs/functions/http-events
    functions.https.onAdminSdkRequest(
      'hello-world',
      (request) async {
        await request.response.send('Hello admin-sdk from Dart Functions!');
      },
      httpsOptions: const FirebaseAdminSdkHttpsOptions(
        cors: FirebaseAdminSdkCors(['*']),
        // Set maxInstances to control costs during unexpected traffic spikes.
        // https://firebase.google.com/docs/functions/manage-functions#min-max-instances
        maxInstances: FirebaseAdminSdkInstances(17),
        region: FirebaseAdminSdkRegion(
          FirebaseAdminSdkSupportedRegion.europeWest1,
        ),
        timeoutSeconds: FirebaseAdminSdkTimeoutSeconds(46),
      ),
    );
  });
}
