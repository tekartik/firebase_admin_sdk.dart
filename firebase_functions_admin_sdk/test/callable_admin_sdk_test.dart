@TestOn('vm')
library;

import 'dart:convert';

import 'package:firebase_functions/firebase_functions.dart' as fn;
import 'package:firebase_functions/testing.dart';
import 'package:tekartik_firebase_admin_sdk/firebase_admin_sdk.dart';
import 'package:tekartik_firebase_functions_admin_sdk/functions_admin_sdk.dart';
import 'package:test/test.dart';

/// The tekartik functions registering on [firebase] (the test instance of
/// the native runtime): the instance a native handler gets.
Future<FirebaseFunctions> _tekartikFunctions(fn.Firebase firebase) async {
  late FirebaseFunctions functions;
  await firebase.callHandler<Object>((ff, request, response) async {
    functions = ff;
    return fn.CallableResult<Object>('');
  })(
    fn.CallableRequest<Object?>(
      Request('POST', Uri.parse('http://localhost/init')),
      null,
      null,
    ),
    fn.CallableResponse<Object>(acceptsStreaming: false),
  );
  return functions;
}

void main() {
  group('callable on the admin sdk runtime', () {
    late FirebaseApp app;
    late FunctionsTestClient client;

    setUpAll(() async {
      app = firebaseAdminSdk.initializeApp(
        options: AppOptions(projectId: 'demo-callable'),
        name: 'callable_admin_sdk_test',
      );
      // The native app type is not a dependency of this package.
      client =
          await (Function.apply(
                runFunctionsTest,
                [
                  (fn.Firebase firebase) async {
                    var functions = await _tekartikFunctions(firebase);
                    functions['returnsMap'] = functions.https.onCall(
                      (request) => {'got': request.data},
                    );
                    functions['returnsNull'] = functions.https.onCall(
                      (request) => null,
                    );
                    functions['returnsNullAsync'] = functions.https.onCall(
                      (request) async => null,
                    );
                    functions['throwsHttpsError'] = functions.https.onCall(
                      (request) => throw FirebaseFunctionsHttpsError(
                        FirebaseFunctionsHttpsErrorCode.permissionDenied,
                        'not yours',
                        {'id': 1},
                      ),
                    );
                    functions['throwsStateError'] = functions.https.onCall(
                      (request) => throw StateError('internal'),
                    );
                  },
                ],
                {#adminApp: (app as dynamic).nativeInstance},
              )
              as Future<FunctionsTestClient>);
    });
    tearDownAll(() async {
      await app.delete();
    });

    Future<(int, Object?)> call(String name, [Object? data]) async {
      var response = await client.call(name, data: data);
      return (response.statusCode, jsonDecode(await response.readAsString()));
    }

    test('a map', () async {
      var (status, body) = await call('returnsMap', 1);
      expect(status, 200);
      expect(body, {
        'result': {'got': 1},
      });
    });

    test('null', () async {
      for (var name in ['returnsNull', 'returnsNullAsync']) {
        var (status, body) = await call(name);
        expect(status, 200, reason: name);
        expect(body, {'result': null}, reason: name);
      }
    });

    test('an HttpsError keeps its code and message', () async {
      var (status, body) = await call('throwsHttpsError');
      expect(status, 403);
      var error = (body as Map)['error'] as Map;
      expect(error['status'], 'PERMISSION_DENIED');
      expect(error['message'], 'not yours');
    });

    test('any other error is internal', () async {
      var (status, body) = await call('throwsStateError');
      expect(status, 500);
      expect(((body as Map)['error'] as Map)['status'], 'INTERNAL');
    });
  });
}
