import 'package:tekartik_firebase_functions_admin_sdk/functions_admin_sdk.dart';

void main(List<String> args) {
  final service = firebaseFunctionsServiceAdminSdk;
  service.fireUp((functions) {
    // https://firebase.google.com/docs/functions/http-events
    functions.registerFunction(
      'hello-world',
      functions.https.onRequest(
        (request) async {
          await request.response.send('Hello common from Dart Functions!');
        },
        httpsOptions: HttpsOptions(
          cors: true,
          region: regionBelgium,
          maxInstances: 15,
          timeoutSeconds: 45,
        ),
      ),
    );
  });
}
