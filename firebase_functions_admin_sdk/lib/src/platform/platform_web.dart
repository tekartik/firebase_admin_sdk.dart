import 'package:tekartik_firebase_functions/firebase_functions.dart';

/// Unsupported on the web
FirebaseFunctionsService get firebaseFunctionsServiceAdminSdk =>
    throw UnsupportedError(
      'firebaseFunctionsServiceAdminSdk not supported on the web',
    );
