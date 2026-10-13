import 'dart:async';

import 'package:tekartik_firebase_functions_admin_sdk/functions_admin_sdk.dart';
import 'package:tekartik_firebase_functions_admin_sdk_http/functions_admin_sdk_http.dart';
import 'package:tekartik_firebase_local/firebase_local.dart';
import 'package:tekartik_http/http_memory.dart';
import 'package:test/test.dart';

void main() {
  test('unknown paths are answered with 404', () async {
    late FirebaseFunctionsAdminSdkHttp functions;
    await runZoned(
      () =>
          FirebaseFunctionsServiceAdminSdkHttp(
            httpServerFactory: httpServerFactoryMemory,
            port: 0,
          ).fireUp(newFirebaseAppMemory(), (firebaseFunctions) {
            functions = firebaseFunctions;
            firebaseFunctions.https.onAdminSdkRequest(
              'hello',
              (_, request) => Response.ok('hello'),
            );
          }),
      zoneSpecification: ZoneSpecification(print: (_, _, _, _) {}),
    );
    var client = httpClientFactoryMemory.newClient();
    addTearDown(() async {
      client.close();
      await functions.httpServer.close(force: true);
    });
    var uri = httpServerGetUri(functions.httpServer);
    Future<int> statusOf(String path) async =>
        (await client
                .get(uri.replace(path: path))
                .timeout(const Duration(seconds: 5)))
            .statusCode;

    expect(await statusOf('/hello'), 200);
    expect(await statusOf('/unknown'), 404);
    expect(await statusOf('/'), 404);
    // Still serving after that.
    expect(await statusOf('/hello'), 200);
  });
}
