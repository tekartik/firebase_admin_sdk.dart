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
      httpsOptions: const FirebaseFunctionsAdminSdkHttpsOptions(
        cors: FirebaseFunctionsAdminSdkCors(['*']),
        // Set maxInstances to control costs during unexpected traffic spikes.
        // https://firebase.google.com/docs/functions/manage-functions#min-max-instances
        maxInstances: FirebaseFunctionsAdminSdkInstances(17),
        region: FirebaseFunctionsAdminSdkRegion(
          FirebaseFunctionsAdminSdkSupportedRegion.europeWest1,
        ),
        timeoutSeconds: FirebaseFunctionsAdminSdkTimeoutSeconds(46),
      ),
    );
  });
}
