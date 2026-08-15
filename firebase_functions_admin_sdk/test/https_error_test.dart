@TestOn('vm')
library;

import 'package:tekartik_firebase_functions_admin_sdk/functions_admin_sdk.dart';
import 'package:test/test.dart';

void main() async {
  // Allow test on the web
  group('FirebaseFunctionsHttpsErrorAdminSdkExt', () {
    test('invalidArgument', () {
      var ffError = FirebaseFunctionsHttpsError(
        FirebaseFunctionsHttpsErrorCode.invalidArgument,
        'message',
        {'key': 'value'},
      );
      expect(ffError.code, FirebaseFunctionsHttpsErrorCode.invalidArgument);
      var adminSdkError = ffError.toAdminSdk();
      expect(adminSdkError.statusCode, 400);
      expect(adminSdkError.status, 'INVALID_ARGUMENT');
      expect(adminSdkError.message, 'message');
      expect(adminSdkError.details, [
        {'key': 'value'},
      ]);
      expect(adminSdkError.toJson(), {
        'error': {
          'code': 400,
          'message': 'message',
          'status': 'INVALID_ARGUMENT',
          'details': [
            {'key': 'value'},
          ],
        },
      });
    });
    test('codes', () {
      // (code, http status code, wire status)
      var expected = [
        (FirebaseFunctionsHttpsErrorCode.cancelled, 499, 'CANCELLED'),
        (FirebaseFunctionsHttpsErrorCode.unknown, 500, 'UNKNOWN'),
        (
          FirebaseFunctionsHttpsErrorCode.invalidArgument,
          400,
          'INVALID_ARGUMENT',
        ),
        (
          FirebaseFunctionsHttpsErrorCode.deadlineExceeded,
          504,
          'DEADLINE_EXCEEDED',
        ),
        (FirebaseFunctionsHttpsErrorCode.notFound, 404, 'NOT_FOUND'),
        (FirebaseFunctionsHttpsErrorCode.alreadyExists, 409, 'ALREADY_EXISTS'),
        (
          FirebaseFunctionsHttpsErrorCode.permissionDenied,
          403,
          'PERMISSION_DENIED',
        ),
        (
          FirebaseFunctionsHttpsErrorCode.resourceExhausted,
          429,
          'RESOURCE_EXHAUSTED',
        ),
        (
          FirebaseFunctionsHttpsErrorCode.failedPrecondition,
          400,
          'FAILED_PRECONDITION',
        ),
        (FirebaseFunctionsHttpsErrorCode.aborted, 409, 'ABORTED'),
        (FirebaseFunctionsHttpsErrorCode.outOrRange, 400, 'OUT_OF_RANGE'),
        (FirebaseFunctionsHttpsErrorCode.unimplemented, 501, 'UNIMPLEMENTED'),
        (FirebaseFunctionsHttpsErrorCode.internal, 500, 'INTERNAL'),
        (FirebaseFunctionsHttpsErrorCode.unavailable, 503, 'UNAVAILABLE'),
        (FirebaseFunctionsHttpsErrorCode.dataLoss, 500, 'DATA_LOSS'),
        (
          FirebaseFunctionsHttpsErrorCode.unauthenticated,
          401,
          'UNAUTHENTICATED',
        ),
      ];
      for (var (code, statusCode, status) in expected) {
        var adminSdkError = FirebaseFunctionsHttpsError(
          code,
          'message',
        ).toAdminSdk();
        expect(adminSdkError.statusCode, statusCode, reason: code);
        expect(adminSdkError.status, status, reason: code);
        expect(adminSdkError.message, 'message', reason: code);
      }
    });
    test('ok and unknown code', () {
      // ok has no http error representation, it falls back to unknown, keeping
      // the original code in the message.
      for (var code in [FirebaseFunctionsHttpsErrorCode.ok, 'dummy']) {
        var adminSdkError = FirebaseFunctionsHttpsError(
          code,
          'message',
        ).toAdminSdk();
        expect(adminSdkError.statusCode, 500, reason: code);
        expect(adminSdkError.status, 'UNKNOWN', reason: code);
        expect(adminSdkError.message, '$code: message', reason: code);
      }
    });
    test('details', () {
      FirebaseFunctionsAdminSdkHttpsError toAdminSdk(Object? details) =>
          FirebaseFunctionsHttpsError(
            FirebaseFunctionsHttpsErrorCode.notFound,
            'message',
            details,
          ).toAdminSdk();
      // null is kept
      expect(toAdminSdk(null).details, isNull);
      // A map is used as is
      expect(toAdminSdk({'key': 'value'}).details, [
        {'key': 'value'},
      ]);
      // A list of maps is used as is
      expect(
        toAdminSdk([
          {'key': 'value'},
        ]).details,
        [
          {'key': 'value'},
        ],
      );
      // Anything else is wrapped
      expect(toAdminSdk('text').details, [
        {'details': 'text'},
      ]);
      expect(toAdminSdk([1, 2]).details, [
        {
          'details': [1, 2],
        },
      ]);
    });
    test('empty message', () {
      // An empty message is not allowed by HttpResponseException
      expect(
        FirebaseFunctionsHttpsError(
          FirebaseFunctionsHttpsErrorCode.notFound,
          '',
        ).toAdminSdk().message,
        FirebaseFunctionsHttpsErrorCode.notFound,
      );
    });
  });
}
