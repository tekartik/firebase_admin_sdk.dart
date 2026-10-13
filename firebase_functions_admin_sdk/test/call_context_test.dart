@TestOn('vm')
library;

import 'package:firebase_functions/firebase_functions.dart' as fn;
import 'package:shelf/shelf.dart';
import 'package:tekartik_firebase_functions_admin_sdk/src/functions_admin_sdk.dart';
import 'package:test/test.dart';

fn.CallableRequest<Object?> _request({
  Map<String, String> headers = const {},
  fn.AuthData? auth,
}) => fn.CallableRequest<Object?>(
  Request('POST', Uri.parse('http://localhost/call'), headers: headers),
  null,
  null,
  auth: auth,
);

void main() {
  group('call context', () {
    test('authenticated uid', () {
      var context = callContextAdminSdkFromRequest(
        _request(auth: const fn.AuthData(uid: 'user-1')),
      );
      expect(context.auth?.uid, 'user-1');
    });
    test('instance id token is never the uid', () {
      // A header any caller can set.
      var headers = {'Firebase-Instance-ID-Token': 'forged'};
      expect(
        callContextAdminSdkFromRequest(_request(headers: headers)).auth,
        isNull,
      );
      expect(
        callContextAdminSdkFromRequest(
          _request(
            headers: headers,
            auth: const fn.AuthData(uid: 'user-1'),
          ),
        ).auth?.uid,
        'user-1',
      );
    });
    test('unauthenticated', () {
      expect(callContextAdminSdkFromRequest(_request()).auth, isNull);
    });
  });
}
