export 'package:firebase_functions/firebase_functions.dart'
    if (dart.library.js_interop) 'src/platform/platform_web.dart';
export 'package:tekartik_firebase_functions/firebase_functions.dart'
    show FirebaseFunctions, FirebaseFunctionsService;

export 'src/functions_admin_sdk.dart'
    if (dart.library.js_interop) 'src/platform/platform_web.dart'
    show
        TekartikFirebaseFunctionsAdminSdkRunner,
        firebaseFunctionsServiceAdminSdk,
        FirebaseFunctionsServiceAdminSdk,
        FirebaseFunctionsAdminSdk,
        FirebaseFunctionsAdminSdkFirebaseExt,
        FirebaseFunctionsAdminSdkRequestHandler,
        FirebaseFunctionsAdminSdkCallHandler;
export 'src/https_error.dart'
    show
        FirebaseFunctionsHttpsError,
        FirebaseFunctionsHttpsErrorCode,
        FirebaseFunctionsHttpsErrorAdminSdkExt;
