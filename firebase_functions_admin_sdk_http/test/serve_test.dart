import 'dart:async';
import 'dart:convert';

import 'package:tekartik_firebase_functions_admin_sdk/functions_admin_sdk.dart';
import 'package:tekartik_firebase_functions_admin_sdk_http/functions_admin_sdk_http.dart';
import 'package:tekartik_firebase_local/firebase_local.dart';
import 'package:tekartik_http/http_memory.dart';
import 'package:test/test.dart';

/// Serves the functions registered by [runner] in memory on any free port.
Future<FirebaseFunctionsAdminSdkHttp> _serve(
  TekartikFirebaseFunctionsAdminSdkHttpRunner runner,
) async {
  late FirebaseFunctionsAdminSdkHttp functions;
  await runZoned(
    () =>
        FirebaseFunctionsServiceAdminSdkHttp(
          httpServerFactory: httpServerFactoryMemory,
          port: 0,
        ).fireUp(newFirebaseAppMemory(), (firebaseFunctions) async {
          functions = firebaseFunctions;
          await runner(firebaseFunctions);
        }),
    zoneSpecification: ZoneSpecification(print: (_, _, _, _) {}),
  );
  addTearDown(() => functions.httpServer.close(force: true));
  return functions;
}

void main() {
  var client = httpClientFactoryMemory.newClient();
  tearDownAll(client.close);

  test('a function calling another function of the server', () async {
    late Uri baseUri;
    var functions = await _serve((functions) {
      functions.https.onAdminSdkRequest(
        'inner',
        (_, request) => Response.ok('inner'),
      );
      functions.https.onAdminSdkRequest('outer', (_, request) async {
        var inner = await client
            .get(baseUri.replace(path: '/inner'))
            .timeout(const Duration(seconds: 5));
        return Response.ok('outer ${inner.body}');
      });
    });
    baseUri = httpServerGetUri(functions.httpServer);
    var response = await client
        .get(baseUri.replace(path: '/outer'))
        .timeout(const Duration(seconds: 10));
    expect(response.body, 'outer inner');
  }, timeout: const Timeout(Duration(seconds: 30)));

  test('a slow function does not hold the other requests', () async {
    var gate = Completer<void>();
    var functions = await _serve((functions) {
      functions.https.onAdminSdkRequest('wait', (_, request) async {
        await gate.future.timeout(const Duration(seconds: 5));
        return Response.ok('waited');
      });
      functions.https.onAdminSdkRequest('open', (_, request) {
        gate.complete();
        return Response.ok('opened');
      });
    });
    var baseUri = httpServerGetUri(functions.httpServer);
    var wait = client.get(baseUri.replace(path: '/wait'));
    var open = await client
        .get(baseUri.replace(path: '/open'))
        .timeout(const Duration(seconds: 10));
    expect(open.body, 'opened');
    expect((await wait.timeout(const Duration(seconds: 10))).body, 'waited');
  }, timeout: const Timeout(Duration(seconds: 30)));

  test('a streamed body is sent', () async {
    var functions = await _serve((functions) {
      functions.https.onAdminSdkRequest(
        'stream',
        (_, request) => Response.ok(
          Stream.fromIterable([utf8.encode('stre'), utf8.encode('amed')]),
        ),
      );
    });
    var response = await client
        .get(httpServerGetUri(functions.httpServer).replace(path: '/stream'))
        .timeout(const Duration(seconds: 10));
    expect(response.statusCode, 200);
    expect(response.body, 'streamed');
  }, timeout: const Timeout(Duration(seconds: 30)));

  test('the handler gets the full path, the function name kept', () async {
    var functions = await _serve((functions) {
      functions.https.onAdminSdkRequest(
        'hello',
        (_, request) => Response.ok(
          jsonEncode({
            'url': request.url.toString(),
            'path': request.requestedUri.path,
          }),
        ),
      );
    });
    var baseUri = httpServerGetUri(functions.httpServer);
    Future<Map> info(String path) async =>
        jsonDecode(
              (await client
                      .get(baseUri.resolve(path))
                      .timeout(const Duration(seconds: 10)))
                  .body,
            )
            as Map;

    // As behind a hosting rewrite (the full path): festenao builds its cms
    // links from requestedUri. A direct function url or the emulator give
    // the path without the function name: not this runner.
    expect(await info('/hello'), {'url': 'hello/', 'path': '/hello/'});
    expect(await info('/hello/'), {'url': 'hello/', 'path': '/hello/'});
    expect((await info('/hello/sub1/sub2?p=1'))['path'], '/hello/sub1/sub2');
  }, timeout: const Timeout(Duration(seconds: 30)));
}
