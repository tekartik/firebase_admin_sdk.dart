import 'package:firebase_functions/firebase_functions.dart' as admin_sdk;
import 'package:tekartik_firebase_functions/firebase_functions.dart' as ff;

/// Error redefinition
typedef FirebaseFunctionsHttpsError = ff.HttpsError;

/// Error code redefinition
typedef FirebaseFunctionsHttpsErrorCode = ff.HttpsErrorCode;

/// Error redefinition
///
/// Since `firebase_functions` 0.7.0 the native error is the shelf
/// [admin_sdk.HttpResponseException] (from `package:google_cloud_shelf`),
/// the previous `HttpsError` hierarchy having been removed.
typedef FirebaseFunctionsAdminSdkHttpsError = admin_sdk.HttpResponseException;

/// Key used to wrap a non map [ff.HttpsError.details] value.
///
/// [admin_sdk.HttpResponseException.details] only accepts a list of string
/// keyed maps while [ff.HttpsError.details] accepts any json value, so scalars
/// and lists of scalars are wrapped in a single `{'details': value}` map.
const firebaseFunctionsAdminSdkDetailsKey = 'details';

Map<String, Object?> _asStringKeyMap(Map map) => {
  for (var entry in map.entries) '${entry.key}': entry.value,
};

/// Converts a free form [ff.HttpsError.details] to the list of maps expected
/// by [admin_sdk.HttpResponseException].
List<Map<String, Object?>>? _wrapDetails(Object? details) {
  if (details == null) {
    return null;
  }
  if (details is Map) {
    return [_asStringKeyMap(details)];
  }
  if (details is List && details.every((item) => item is Map)) {
    return details.map((item) => _asStringKeyMap(item as Map)).toList();
  }
  return [
    {firebaseFunctionsAdminSdkDetailsKey: details},
  ];
}

/// Extension on firebase functions error
extension FirebaseFunctionsHttpsErrorAdminSdkExt
    on FirebaseFunctionsHttpsError {
  /// A non empty message, as required by [admin_sdk.HttpResponseException].
  String get _adminSdkMessage {
    if (message.isNotEmpty) {
      return message;
    }
    if (code.isNotEmpty) {
      return code;
    }
    return 'Unknown error';
  }

  /// Convert to admin sdk error
  ///
  /// An unknown code (including [ff.HttpsErrorCode.ok], which has no
  /// representation as an http error status) becomes a `500`/`UNKNOWN` error
  /// keeping the original code in the message.
  admin_sdk.HttpResponseException toAdminSdk() {
    var adminSdkMessage = _adminSdkMessage;
    var adminSdkDetails = _wrapDetails(details);
    switch (code) {
      case ff.HttpsErrorCode.cancelled:
        return admin_sdk.HttpResponseException(
          499,
          adminSdkMessage,
          status: 'CANCELLED',
          details: adminSdkDetails,
        );
      case ff.HttpsErrorCode.unknown:
        return admin_sdk.HttpResponseException(
          500,
          adminSdkMessage,
          status: 'UNKNOWN',
          details: adminSdkDetails,
        );
      case ff.HttpsErrorCode.invalidArgument:
        return admin_sdk.HttpResponseException.badRequest(
          message: adminSdkMessage,
          details: adminSdkDetails,
        );
      case ff.HttpsErrorCode.deadlineExceeded:
        return admin_sdk.HttpResponseException.gatewayTimeout(
          message: adminSdkMessage,
          details: adminSdkDetails,
        );
      case ff.HttpsErrorCode.notFound:
        return admin_sdk.HttpResponseException.notFound(
          message: adminSdkMessage,
          details: adminSdkDetails,
        );
      case ff.HttpsErrorCode.alreadyExists:
        return admin_sdk.HttpResponseException.conflict(
          message: adminSdkMessage,
          details: adminSdkDetails,
        );
      case ff.HttpsErrorCode.permissionDenied:
        return admin_sdk.HttpResponseException.forbidden(
          message: adminSdkMessage,
          details: adminSdkDetails,
        );
      case ff.HttpsErrorCode.resourceExhausted:
        return admin_sdk.HttpResponseException.tooManyRequests(
          message: adminSdkMessage,
          details: adminSdkDetails,
        );
      case ff.HttpsErrorCode.failedPrecondition:
        return admin_sdk.HttpResponseException(
          400,
          adminSdkMessage,
          status: 'FAILED_PRECONDITION',
          details: adminSdkDetails,
        );
      case ff.HttpsErrorCode.aborted:
        return admin_sdk.HttpResponseException(
          409,
          adminSdkMessage,
          status: 'ABORTED',
          details: adminSdkDetails,
        );
      case ff.HttpsErrorCode.outOrRange:
        return admin_sdk.HttpResponseException(
          400,
          adminSdkMessage,
          status: 'OUT_OF_RANGE',
          details: adminSdkDetails,
        );
      case ff.HttpsErrorCode.unimplemented:
        return admin_sdk.HttpResponseException.notImplemented(
          message: adminSdkMessage,
          details: adminSdkDetails,
        );
      case ff.HttpsErrorCode.internal:
        return admin_sdk.HttpResponseException.internalServerError(
          message: adminSdkMessage,
          details: adminSdkDetails,
        );
      case ff.HttpsErrorCode.unavailable:
        return admin_sdk.HttpResponseException.serviceUnavailable(
          message: adminSdkMessage,
          details: adminSdkDetails,
        );
      case ff.HttpsErrorCode.dataLoss:
        return admin_sdk.HttpResponseException(
          500,
          adminSdkMessage,
          status: 'DATA_LOSS',
          details: adminSdkDetails,
        );
      case ff.HttpsErrorCode.unauthenticated:
        return admin_sdk.HttpResponseException.unauthorized(
          message: adminSdkMessage,
          details: adminSdkDetails,
        );
    }
    return admin_sdk.HttpResponseException(
      500,
      '$code: $adminSdkMessage',
      status: 'UNKNOWN',
      details: adminSdkDetails,
    );
  }
}
