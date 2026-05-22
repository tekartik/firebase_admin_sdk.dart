import 'package:tekartik_firebase_functions_admin_sdk/functions_admin_sdk.dart';

void main(List<String> args) {
  var service = firebaseFunctionsServiceAdminSdk;
  service.fireUp((functions) {
    // https://firebase.google.com/docs/functions/http-events
    functions.httpsAdminSdk.onRequest(
      name: 'hello-world',
      options: const FirebaseFunctionsAdminSdkHttpsOptions(
        cors: FirebaseFunctionsAdminSdkCors(['*']),
        // Set maxInstances to control costs during unexpected traffic spikes.
        // https://firebase.google.com/docs/functions/manage-functions#min-max-instances
        maxInstances: FirebaseFunctionsAdminSdkInstances(13),
        region: FirebaseFunctionsAdminSdkRegion(
          FirebaseFunctionsAdminSdkSupportedRegion.europeWest1,
        ),
        timeoutSeconds: FirebaseFunctionsAdminSdkTimeoutSeconds(37),
      ),
      (request) async => FirebaseFunctionsAdminSdkResponse(
        200,
        body: 'Hello raw4 from Dart Functions!',
      ),
    );
  });
}
