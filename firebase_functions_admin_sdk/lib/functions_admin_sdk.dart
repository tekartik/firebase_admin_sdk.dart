export 'package:firebase_functions/firebase_functions.dart'
    if (dart.library.js_interop) 'src/platform/platform_web.dart';

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
