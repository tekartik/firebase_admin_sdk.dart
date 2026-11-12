@TestOn('vm')
library;

import 'dart:convert';

import 'package:tekartik_firebase_functions_admin_sdk_test/functions.dart';
import 'package:tekartik_firebase_functions_admin_sdk_test/http_test_context.dart';
import 'package:tekartik_firebase_local/firebase_local.dart';
import 'package:tekartik_http/http.dart';
import 'package:tekartik_http/http_memory.dart';
import 'package:test/test.dart';

FirebaseFunctionsAdminSdkHttpTestContext _newContext({
  HttpFactory? httpFactory,
}) => FirebaseFunctionsAdminSdkHttpTestContext(
  app: newFirebaseAppMemory(),
  declarer: (functions) => basicDeclareRunner(functions, prefix: 'ctx'),
  httpFactory: httpFactory,
);

/// Calls the basic echo function of [context].
Future<Object?> _echo(
  FirebaseFunctionsAdminSdkHttpTestContext context,
  String text,
) async {
  var response = await httpClientSend(
    context.client,
    httpMethodPost,
    context.httpsUri('ctxbasic'),
    headers: (HttpHeaders()..mimeType = httpContentTypeJson).toStringMap(),
    body: jsonEncode({
      'data': {'command': 'echo', 'data': text},
    }),
  );
  expect(response.statusCode, httpStatusCodeOk, reason: response.body);
  return (jsonDecode(response.body) as Map)['result'];
}

void main() {
  for (var entry in {'io': null, 'memory': httpFactoryMemory}.entries) {
    group(entry.key, () {
      test('set up again after the last tear down', () async {
        var context = _newContext(httpFactory: entry.value);
        await context.setUpAll();
        expect(await _echo(context, 'first'), 'first');
        await context.tearDownAll();

        // A group run after the previous one released the context.
        await context.setUpAll();
        try {
          expect(await _echo(context, 'second'), 'second');
        } finally {
          await context.tearDownAll();
        }
      }, timeout: const Timeout(Duration(seconds: 30)));

      test('two contexts at once', () async {
        var context1 = _newContext(httpFactory: entry.value);
        var context2 = _newContext(httpFactory: entry.value);
        await context1.setUpAll();
        try {
          await context2.setUpAll();
          try {
            expect(await _echo(context1, 'one'), 'one');
            expect(await _echo(context2, 'two'), 'two');
          } finally {
            await context2.tearDownAll();
          }
        } finally {
          await context1.tearDownAll();
        }
      }, timeout: const Timeout(Duration(seconds: 30)));
    });
  }
}
