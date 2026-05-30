import 'package:tekartik_firebase_functions_admin_sdk_test/test_context.dart';
import 'package:dev_test/dev_test.dart';
import 'package:http/http.dart';
import 'package:tekartik_http/common/http_headers_memory.dart';
import 'package:tekartik_http/http.dart';
import 'package:tekartik_http/http.dart';
import 'functions.dart';
import 'package:cv/cv_json.dart';

extension on Uri {
  Uri withInfo() => replace(queryParameters: {'info': 'true'});
}

void functionsHttpGroup(FirebaseFunctionsAdminSdkTestContext context) {
  late Client client;
  setUpAll(() async {
    await context.setUpAll();
    client = context.client;
  });

  /// Most basic
  test('hello', () async {
    var uri = context.httpsUri(testFunctionHttpsV1);
    var result = await httpClientRead(client, httpMethodGet, uri);
    // ignore: avoid_print
    print('helloWorld: $result');
    expect(result, contains('Hello'));
    var response = await httpClientSend(client, httpMethodGet, uri);
    expect(response.statusCode, 200);
    // headers:
    // {
    //             'connection': 'keep-alive',
    //             'x-powered-by': 'Dart with package:shelf',
    //             'access-control-allow-headers': '*',
    //             'keep-alive': 'timeout=5',
    //             'date': 'Sat, 30 May 2026 10:10:36 GMT',
    //             'access-control-allow-origin': '*',
    //             'access-control-allow-methods': '*',
    //             'content-length': '5',
    //             'content-type': 'text/plain; charset=utf-8',
    //             'x-frame-options': 'SAMEORIGIN',
    //             'x-xss-protection': '1; mode=block',
    //             'x-content-type-options': 'nosniff'
    //           }
    expect(response.headers['content-length'], '5');
  });
  test('?info', () async {
    var uri = context.httpsUri(testFunctionHttpsV1).withInfo();
    var result = await httpClientRead(client, httpMethodGet, uri);
    var map = result.jsonToMap();
    // {
    //   "url": "admin-sdk-https-v1/?info=true",
    //   "requestedUri": "http://localhost:5001/admin-sdk-https-v1/?info=true",
    //   "method": "GET",
    //   "protocolVersion": "1.1"
    // }
    // ignore: avoid_print
    print(map.cvToJsonPretty());
    expect(map['requestedUri'], endsWith('/admin-sdk-https-v1/?info=true'));
    map.remove('requestedUri');
    expect(map, {
      'url': 'admin-sdk-https-v1/?info=true',
      'method': 'GET',
      'protocolVersion': '1.1',
    });

    result = await httpClientRead(client, httpMethodGet, uri, body: 'test');
    map = result.jsonToMap();

    // ignore: avoid_print
    print(map.cvToJsonPretty());
    expect(map['body'], 'test');
    expect(map['mimeType'], 'text/plain');
    expect(map['contentLength'], 4);

    result = await httpClientRead(
      client,
      httpMethodGet,
      uri,
      body: [0xC0, 0x80],
    );
    map = result.jsonToMap();
    // ignore: avoid_print
    print(map.cvToJsonPretty());
    expect(map['bodyBytes'], [0xC0, 0x80]);
    expect(map['mimeType'], isNull);
    expect(map['contentLength'], 2);

    result = await httpClientRead(
      client,
      httpMethodGet,
      uri,
      body: [0xC0, 0x80],
      headers: (HttpHeaders()..mimeType = httpContentTypeBytes).toStringMap(),
    );
    map = result.jsonToMap();
    // ignore: avoid_print
    print(map.cvToJsonPretty());
    expect(map['bodyBytes'], [0xC0, 0x80]);
    expect(map['mimeType'], httpContentTypeBytes);
    expect(map['contentLength'], 2);
  });
}
