//import 'package:tekartik_firebase_functions/firebase_functions.dart';

import 'package:firebase_admin_sdk/firebase_admin_sdk.dart' as sdk;

import 'package:tekartik_firebase/firebase_admin.dart';
import 'package:tekartik_firebase/firebase_mixin.dart';

import 'firebase_admin_sdk_common.dart';

/// AdminSdk firebase api
FirebaseAdminSdk get firebaseAdminSdk => prvFirebaseAdminSdk;

/// Admin SDK specific firebase app options.
abstract class FirebaseAppOptionsAdminSdk implements FirebaseAppOptions {}

/// Admin SDK specific firebase implementation.
abstract class TekartikFirebaseAdminSdk implements FirebaseAdminSdk {}

/// Internal Admin SDK firebase API entry point.
TekartikFirebaseAdminSdk get prvFirebaseAdminSdk => _TekartikFirebaseAdminSdk();

class _FirebaseAppOptionsWithCredential
    with FirebaseAppOptionsMixin
    implements FirebaseAppOptionsAdminSdk {
  final sdk.Credential credential;
  final FirebaseAppOptions appOptions;

  _FirebaseAppOptionsWithCredential({
    required this.credential,
    required this.appOptions,
  });

  @override
  String? get apiKey => appOptions.apiKey;

  @override
  String? get appId => appOptions.appId;

  @override
  String? get authDomain => appOptions.authDomain;

  @override
  String? get databaseURL => appOptions.databaseURL;

  @override
  String? get measurementId => appOptions.measurementId;

  @override
  String? get messagingSenderId => appOptions.messagingSenderId;

  @override
  String? get projectId => appOptions.projectId;

  @override
  String? get storageBucket => appOptions.storageBucket;

  @override
  Map<String, Object?> toDebugMap() => appOptions.toDebugMap();
}

/// Rest extension.
extension FirebaseAdminSdkExtension on FirebaseAdminSdk {}

/// Mixin
extension TekartikFirebaseMixinAdminSdkExtension on FirebaseAdminSdk {
  _TekartikFirebaseAdminSdk get _impl => this as _TekartikFirebaseAdminSdk;

  /// From raw app
  FirebaseApp fromNativeApp(sdk.FirebaseApp rawApp) {
    return _impl._fromRawAppSdk(rawApp);
  }
}

// ignore: unused_element
sdk.AppOptions? _unwrapAppOptions(FirebaseAppOptions appOptions) {
  return sdk.AppOptions(
    projectId: appOptions.projectId,
    storageBucket: appOptions.storageBucket,
  );
}

FirebaseAppOptions _wrapAppOptions(sdk.AppOptions rawAppOptions) {
  return FirebaseAppOptions(
    projectId: rawAppOptions.projectId,
    storageBucket: rawAppOptions.storageBucket,
  );
}

class _TekartikFirebaseAdminSdk
    with FirebaseWithAppsMixin, FirebaseAdminMixin, FirebaseMixin
    implements
        Firebase,
        FirebaseAdmin,
        FirebaseAdminSdk,
        TekartikFirebaseAdminSdk {
  FirebaseApp _fromRawAppSdk(
    sdk.FirebaseApp rawAppSdk, {
    FirebaseAppOptions? options,
  }) {
    var app = _TekartikFirebaseAppAdminSdk(
      this,
      rawAppSdk,
      options ?? _wrapAppOptions(rawAppSdk.options),
    );
    return addApp(app);
  }

  FirebaseAppOptions? _fixOptions(FirebaseAppOptions? options) {
    if (options == null) {
      return options;
    }
    return options;
  }

  sdk.AppOptions? _toRawOptions(FirebaseAppOptions? options) {
    if (options == null) {
      return null;
    }
    if (options is _FirebaseAppOptionsWithCredential) {
      return sdk.AppOptions(
        credential: options.credential,
        projectId: options.projectId,
        storageBucket: options.storageBucket,
      );
    }
    return sdk.AppOptions(
      projectId: options.projectId,
      storageBucket: options.storageBucket,
    );
  }

  /// Initialize rest with a service account json map.
  @override
  Future<FirebaseApp> initializeAppWithServiceAccountMap(
    Map map, {

    /// Overiden options (storage bucket, database url, ...)
    FirebaseAppOptions? options,
  }) async {
    var projectId = map['project_id']!.toString();
    var credential = sdk.Credential.fromServiceAccountParams(
      clientId: map['client_id']?.toString(),
      privateKey: map['private_key']!.toString(),
      email: map['client_email']!.toString(),
      projectId: projectId,
    );

    var newOptions = _FirebaseAppOptionsWithCredential(
      credential: credential,
      appOptions: FirebaseAppOptions(
        projectId: projectId,
        storageBucket: options?.storageBucket,
      ),
    );

    return initializeApp(options: newOptions);
  }

  @override
  FirebaseApp initializeApp({AppOptions? options, String? name}) {
    sdk.FirebaseApp rawAppSdk;
    final rawAppOptions = _toRawOptions(options);
    rawAppSdk = sdk.FirebaseApp.initializeApp(
      options: rawAppOptions,
      name: name,
    );
    if (options != null) {
      options = _fixOptions(options);
    }
    return _fromRawAppSdk(rawAppSdk, options: options);
  }

  String get name => 'admin_sdk';
  String get tag => 'admin_sdk';

  @override
  String toString() => 'FirebaseAdminSdk($name)';
}

class _TekartikFirebaseAppAdminSdk
    with FirebaseAppMixin
    implements FirebaseAppAdminSdk {
  final _TekartikFirebaseAdminSdk _firebase;
  @override
  FirebaseAdminSdk get firebase => _firebase;
  final sdk.FirebaseApp _app;
  @override
  bool get hasAdminCredentials => true;
  @override
  String get name => _app.name;

  @override
  Future<void> delete() async {
    await super.delete();
    await sdk.FirebaseApp.deleteApp(_app);
  }

  _TekartikFirebaseAppAdminSdk(this._firebase, this._app, this.options);

  @override
  final FirebaseAppOptions options;

  sdk.FirebaseApp get nativeInstance => _app;
}
