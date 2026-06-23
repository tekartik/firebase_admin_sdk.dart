import 'package:firebase_functions/firebase_functions.dart' as admin_sdk;
import 'package:tekartik_firebase_functions/firebase_functions.dart' as ff;

/// Error redefinition
typedef FirebaseFunctionsHttpsError = ff.HttpsError;

/// Error code redefinition
typedef FirebaseFunctionsHttpsErrorCode = ff.HttpsErrorCode;

/// Error redefinition
typedef FirebaseFunctionsAdminSdkHttpsError = admin_sdk.HttpsError;

/// Extension on firebase functions error
extension FirebaseFunctionsHttpsErrorAdminSdkExt
    on FirebaseFunctionsHttpsError {
  /// Convert to admin sdk error
  admin_sdk.HttpsError toAdminSdk() {
    switch (code) {
      case ff.HttpsErrorCode.ok:
        return admin_sdk.GenericHttpsError(
          admin_sdk.FunctionsErrorCode.ok,
          message,
          details,
        );
      case ff.HttpsErrorCode.cancelled:
        return admin_sdk.CancelledError(message, details);
      case ff.HttpsErrorCode.unknown:
        return admin_sdk.UnknownError(message, details);
      case ff.HttpsErrorCode.invalidArgument:
        return admin_sdk.InvalidArgumentError(message, details);
      case ff.HttpsErrorCode.deadlineExceeded:
        return admin_sdk.DeadlineExceededError(message, details);
      case ff.HttpsErrorCode.notFound:
        return admin_sdk.NotFoundError(message, details);
      case ff.HttpsErrorCode.alreadyExists:
        return admin_sdk.AlreadyExistsError(message, details);
      case ff.HttpsErrorCode.permissionDenied:
        return admin_sdk.PermissionDeniedError(message, details);
      case ff.HttpsErrorCode.resourceExhausted:
        return admin_sdk.ResourceExhaustedError(message, details);
      case ff.HttpsErrorCode.failedPrecondition:
        return admin_sdk.FailedPreconditionError(message, details);
      case ff.HttpsErrorCode.aborted:
        return admin_sdk.AbortedError(message, details);
      case ff.HttpsErrorCode.outOrRange:
        return admin_sdk.OutOfRangeError(message, details);
      case ff.HttpsErrorCode.unimplemented:
        return admin_sdk.UnimplementedError(message, details);
      case ff.HttpsErrorCode.internal:
        return admin_sdk.InternalError(message, details);
      case ff.HttpsErrorCode.unavailable:
        return admin_sdk.UnavailableError(message, details);
      case ff.HttpsErrorCode.dataLoss:
        return admin_sdk.DataLossError(message, details);
      case ff.HttpsErrorCode.unauthenticated:
        return admin_sdk.UnauthenticatedError(message, details);
    }
    return admin_sdk.UnknownError('$code: $message', details);
  }
}
