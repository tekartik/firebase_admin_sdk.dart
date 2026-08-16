import 'package:firebase_functions/firebase_functions.dart';

/// DON'T TRY TO FIX ERROR
/// a work is in progress in the admin_sdk_v7 branch
class HttpResponseException {
  /// Future compat
  static HttpsError badRequest({String? message}) {
    return FailedPreconditionError(message ?? 'Bad request');
  }
}
