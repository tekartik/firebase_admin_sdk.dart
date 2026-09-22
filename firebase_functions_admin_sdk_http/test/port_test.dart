import 'dart:async';

import 'package:tekartik_firebase_functions_admin_sdk/functions_admin_sdk.dart';
import 'package:tekartik_firebase_functions_admin_sdk_http/functions_admin_sdk_http.dart';
import 'package:tekartik_firebase_functions_http/firebase_functions_http.dart'
    show firebaseFunctionsHttpDefaultPort;
import 'package:tekartik_firebase_local/firebase_local.dart';
import 'package:tekartik_http/http_memory.dart';
import 'package:test/test.dart';

/// Serves a `hello` function with [service] in memory, returning the
/// functions and what the runner printed.
Future<(FirebaseFunctionsAdminSdkHttp, List<String>)> _serve(
  FirebaseFunctionsServiceAdminSdkHttp service,
) async {
  var printed = <String>[];
  late FirebaseFunctionsAdminSdkHttp functions;
  await runZoned(
    () => service.fireUp(newFirebaseAppMemory(), (firebaseFunctions) {
      functions = firebaseFunctions;
      firebaseFunctions.https.onAdminSdkRequest(
        'hello',
        (_, request) => Response.ok('hello'),
      );
    }),
    zoneSpecification: ZoneSpecification(
      print: (self, parent, zone, line) => printed.add(line),
    ),
  );
  addTearDown(() => functions.httpServer.close(force: true));
  return (functions, printed);
}

void main() {
  var client = httpClientFactoryMemory.newClient();
  tearDownAll(client.close);

  test('the default port', () async {
    var (functions, _) = await _serve(
      FirebaseFunctionsServiceAdminSdkHttp(
        httpServerFactory: httpServerFactoryMemory,
      ),
    );
    expect(functions.httpServer.port, firebaseFunctionsHttpDefaultPort);
  });

  test('a given port, listed as such', () async {
    var (functions, printed) = await _serve(
      FirebaseFunctionsServiceAdminSdkHttp(
        httpServerFactory: httpServerFactoryMemory,
        port: 8041,
      ),
    );
    var server = functions.httpServer;
    expect(server.port, 8041);
    expect(printed, [
      'hello http://localhost:8041/hello',
      'listening on http://localhost:8041',
    ]);
    var response = await client.get(
      httpServerGetUri(server).replace(path: '/hello'),
    );
    expect(response.body, 'hello');
  });

  test('any free port', () async {
    var (functions, printed) = await _serve(
      newFirebaseFunctionsServiceAdminSdkHttp(
        httpServerFactory: httpServerFactoryMemory,
        port: 0,
      ),
    );
    var port = functions.httpServer.port;
    expect(port, isNot(0));
    // The port bound is the one listed.
    expect(printed.first, 'hello http://localhost:$port/hello');
  });
}
