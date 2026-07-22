import 'package:firebase_admin_sdk/auth.dart' as admin_sdk;
import 'package:firebase_admin_sdk/auth.dart' as sdk;
import 'package:firebase_admin_sdk/firebase_admin_sdk.dart' as admin_sdk;
import 'package:tekartik_firebase/firebase_mixin.dart';
import 'package:tekartik_firebase_admin_sdk/firebase_admin_sdk.dart';
import 'package:tekartik_firebase_auth/auth_admin.dart';
import 'package:tekartik_firebase_auth/auth_mixin.dart';

import 'firebase_admin_sdk_common.dart';

/// Auth service implementation for Admin SDK.
class _FirebaseAuthServiceAdminSdk
    with FirebaseProductServiceMixin<FirebaseAuth>, FirebaseAuthServiceMixin
    implements FirebaseAuthServiceAdminSdk {
  @override
  Auth auth(App app) {
    return getInstance(app, () {
      assert(app is FirebaseAppAdminSdk, 'invalid firebase app type');
      var adminApp = app as FirebaseAppAdminSdk;
      var sdkApp =
          (adminApp as dynamic).nativeInstance as admin_sdk.FirebaseApp;

      return AuthAdminSdk(this, adminApp, sdkApp.auth());
    });
  }

  @override
  bool get supportsCurrentUser => false;

  @override
  bool get supportsListUsers => true;
}

FirebaseAuthServiceAdminSdk? _authServiceAdminSdk;

/// The auth service for admin sdk.
FirebaseAuthServiceAdminSdk get firebaseAuthServiceAdminSdk =>
    _authServiceAdminSdk ??= _FirebaseAuthServiceAdminSdk();

/// Auth Admin SDK.
abstract class FirebaseAuthAdminSdk
    implements FirebaseAuth, FirebaseAuthAdmin {}

/// Auth implementation for Admin SDK.
class AuthAdminSdk
    with
        FirebaseAppProductMixin<FirebaseAuth>,
        FirebaseAuthMixin,
        FirebaseAuthAdminDefaultMixin
    implements FirebaseAuthAdminSdk {
  @override
  final FirebaseAuthServiceAdminSdk service;

  /// admin sdk app
  final FirebaseAppAdminSdk appAdminSdk;

  /// Native instance
  final admin_sdk.Auth nativeInstance;

  /// Constructor
  AuthAdminSdk(this.service, this.appAdminSdk, this.nativeInstance);

  @override
  App get app => appAdminSdk;

  @override
  Future<ListUsersResult> listUsers({
    int? maxResults,
    String? pageToken,
  }) async {
    var nativeResult = await nativeInstance.listUsers(
      maxResults: maxResults,
      pageToken: pageToken,
    );
    return ListUsersResult(
      pageToken: nativeResult.pageToken,
      users: nativeResult.users.map((user) {
        return _UserRecordAdminSdk(user);
      }).toList(),
    );
  }

  @override
  Future<void> deleteUser(String uid) async {
    await nativeInstance.deleteUser(uid);
  }

  @override
  Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    var userRecord = await createUser(
      FirebaseAuthCreateUserRequest(email: email, password: password),
    );
    var user = _UserAdminSdk(
      uid: userRecord.uid,
      email: userRecord.email,
      displayName: userRecord.displayName,
      emailVerified: userRecord.emailVerified,
      phoneNumber: userRecord.phoneNumber,
      photoURL: userRecord.photoURL,
    );
    return _UserCredentialAdminSdk(
      credential: _AuthCredentialAdminSdk(),
      user: user,
    );
  }

  @override
  Future<UserRecord> createUser(FirebaseAuthCreateUserRequest request) async {
    var nativeUser = await nativeInstance.createUser(
      admin_sdk.CreateRequest(
        uid: request.uid,
        email: request.email,
        password: request.password,
        //displayName: request.displayName,
        //phoneNumber: request.phoneNumber,
        //emailVerified: request.emailVerified,
        disabled: request.disabled,
      ),
    );
    return _UserRecordAdminSdk(nativeUser);
  }

  @override
  Future<UserRecord?> getUser(String uid) async {
    try {
      var nativeUser = await nativeInstance.getUser(uid);
      return _UserRecordAdminSdk(nativeUser);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<UserRecord?> getUserByEmail(String email) async {
    try {
      var nativeUser = await nativeInstance.getUserByEmail(email);
      return _UserRecordAdminSdk(nativeUser);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<User> reloadCurrentUser() => throw UnsupportedError(
    'reloadCurrentUser not supported for admin sdk yet',
  );
}

class _UserRecordAdminSdk
    with FirebaseUserRecordDefaultMixin
    implements UserRecord {
  final sdk.UserRecord nativeUserRecord;

  _UserRecordAdminSdk(this.nativeUserRecord);

  @override
  String? get email => nativeUserRecord.email;

  @override
  String get uid => nativeUserRecord.uid;

  @override
  Object? get customClaims => nativeUserRecord.customClaims;

  @override
  bool get disabled => nativeUserRecord.disabled;

  @override
  String? get displayName => nativeUserRecord.displayName;

  @override
  bool get emailVerified => nativeUserRecord.emailVerified;

  @override
  bool get isAnonymous => nativeUserRecord.email?.trim().isEmpty ?? true;

  //  @override
  //  UserMetadata? get metadata => nativeUserRecord.metadata;

  @override
  String? get passwordHash => nativeUserRecord.passwordHash;

  @override
  String? get passwordSalt => nativeUserRecord.passwordSalt;

  @override
  String? get phoneNumber => nativeUserRecord.phoneNumber;

  @override
  String? get photoURL => nativeUserRecord.photoUrl;

  //  @override
  //  List<UserInfo>? get providerData => nativeUserRecord.providerData;

  @override
  String? get tokensValidAfterTime =>
      nativeUserRecord.tokensValidAfterTime?.toIso8601String();
}

class _UserAdminSdk with FirebaseUserMixin implements User {
  @override
  final String uid;

  @override
  final String? email;

  @override
  final String? displayName;

  @override
  final bool emailVerified;

  @override
  bool get isAnonymous => email?.trim().isEmpty ?? true;

  @override
  final String? phoneNumber;

  @override
  final String? photoURL;

  @override
  String? get providerId => null;

  _UserAdminSdk({
    required this.uid,
    this.email,
    this.displayName,
    this.emailVerified = false,
    this.phoneNumber,
    this.photoURL,
  });
}

class _UserCredentialAdminSdk implements UserCredential {
  @override
  final AuthCredential credential;

  @override
  final User user;

  _UserCredentialAdminSdk({required this.credential, required this.user});
}

class _AuthCredentialAdminSdk implements AuthCredential {
  @override
  String get providerId => 'google.com';
}
