import 'dart:async';
import 'dart:typed_data';

import 'package:firebase_admin_sdk/firebase_admin_sdk.dart' as admin_sdk;
import 'package:firebase_admin_sdk/storage.dart' as admin_sdk;
import 'package:google_cloud_protobuf/protobuf.dart' as sdk;
import 'package:google_cloud_storage/google_cloud_storage.dart' as sdk;
import 'package:tekartik_firebase/firebase_mixin.dart';
import 'package:tekartik_firebase_admin_sdk/firebase_admin_sdk.dart';
import 'package:tekartik_firebase_admin_sdk/firestore_admin_sdk.dart';
import 'package:tekartik_firebase_storage/storage.dart';
import 'package:tekartik_firebase_storage/storage_mixin.dart';
import 'package:tekartik_firebase_storage/utils/content_type.dart';

import 'firebase_admin_sdk_common.dart';

/// Storage service implementation for Admin SDK.
class _FirebaseStorageServiceAdminSdk
    with
        FirebaseProductServiceMixin<FirebaseStorage>,
        FirebaseStorageServiceMixin
    implements FirebaseStorageServiceAdminSdk {
  @override
  FirebaseStorage storage(App app) {
    return getInstance(app, () {
      assert(app is FirebaseAppAdminSdk, 'invalid firebase app type');
      var adminApp = app as FirebaseAppAdminSdk;
      var sdkApp =
          (adminApp as dynamic).nativeInstance as admin_sdk.FirebaseApp;

      return FirebaseStorageAdminSdk(this, adminApp, sdkApp.storage());
    });
  }
}

FirebaseStorageServiceAdminSdk? _storageServiceAdminSdk;

/// The storage service for admin sdk.
FirebaseStorageServiceAdminSdk get firebaseStorageServiceAdminSdk =>
    _storageServiceAdminSdk ??= _FirebaseStorageServiceAdminSdk();

/// Firebase Storage Admin SDK implementation.
class FirebaseStorageAdminSdk
    with FirebaseAppProductMixin<FirebaseStorage>, FirebaseStorageMixin
    implements FirebaseStorage {
  @override
  final FirebaseStorageService service;

  /// Admin SDK app
  final FirebaseAppAdminSdk appAdminSdk;

  /// Native SDK instance
  final admin_sdk.Storage nativeInstance;

  /// Constructor
  FirebaseStorageAdminSdk(this.service, this.appAdminSdk, this.nativeInstance);

  @override
  App get app => appAdminSdk;

  @override
  Bucket bucket([String? name]) {
    var bucketName = name ?? app.options.storageBucket;
    if (bucketName == null) {
      throw StateError(
        'No bucket name provided and no default bucket in options',
      );
    }

    return BucketAdminSdk(this, nativeInstance.bucket(bucketName));
  }

  @override
  Reference ref([String? path]) {
    return ReferenceAdminSdk(bucket(), path ?? '');
  }
}

/// Bucket implementation for Admin SDK.
class BucketAdminSdk with BucketMixin implements Bucket {
  /// Storage instance
  final FirebaseStorageAdminSdk storageAdminSdk;

  /// Native bucket instance
  final sdk.Bucket nativeInstance;

  /// Constructor
  BucketAdminSdk(this.storageAdminSdk, this.nativeInstance);

  @override
  String get name => nativeInstance.name;

  @override
  File file(String path) => FileAdminSdk(this, nativeInstance.object(path));

  @override
  Future<bool> exists() async {
    try {
      await nativeInstance.metadata();
      return true;
    } on sdk.NotFoundException {
      return false;
    }
  }

  @override
  Future<void> create() => nativeInstance.create();

  @override
  Future<GetFilesResponse> getFiles([GetFilesOptions? options]) async {
    var stream = nativeInstance.storage.listObjects(
      nativeInstance.name,
      maxResults: options?.maxResults,
      prefix: options?.prefix,
    );
    final objects = await stream.toList();

    return GetFilesResponse(
      files: objects
          .map((f) => FileAdminSdk(this, nativeInstance.object(f.name!)))
          .toList(),
      nextQuery:
          null, // Simple implementation for now as stream handles pagination
    );
  }
}

extension on StorageUploadFileOptions {
  sdk.ObjectMetadata toObjectMetaData(String name) {
    var contentType =
        this.contentType ?? firebaseStorageContentTypeFromFilename(name);

    return sdk.ObjectMetadata(contentType: contentType);
  }
}

/// File implementation for Admin SDK.
class FileAdminSdk with FileMixin implements File {
  /// Bucket instance
  @override
  final BucketAdminSdk bucket;

  /// Native file instance
  final sdk.StorageObject nativeInstance;

  /// Constructor
  FileAdminSdk(this.bucket, this.nativeInstance);

  @override
  String get name => nativeInstance.name;

  @override
  Future<void> upload(Uint8List bytes, {StorageUploadFileOptions? options}) =>
      nativeInstance.upload(
        bytes,
        metadata: (options ?? StorageUploadFileOptions()).toObjectMetaData(
          name,
        ),
      );

  @override
  Future<bool> exists() async {
    try {
      await nativeInstance.metadata();
      return true;
    } on sdk.NotFoundException {
      return false;
    }
  }

  @override
  Future<Uint8List> download() => nativeInstance.download();

  @override
  Future<void> delete() => nativeInstance.delete();

  @override
  FileMetadata? get metadata => null;

  @override
  Future<FileMetadata> getMetadata() async {
    var sdkMetadata = await nativeInstance.metadata();

    return FileMetadataAdminSdk(sdkMetadata);
  }
}

extension on sdk.Timestamp {
  DateTime timestampToDateTime() {
    return Timestamp(seconds, nanos).toDateTime();
  }
}

/// File metadata implementation for Admin SDK.
class FileMetadataAdminSdk with FileMetadataMixin implements FileMetadata {
  /// Native metadata instance
  final sdk.ObjectMetadata nativeInstance;

  /// Constructor
  FileMetadataAdminSdk(this.nativeInstance);

  @override
  int get size => nativeInstance.size?.toInt() ?? 0;

  @override
  DateTime get dateUpdated =>
      nativeInstance.updated?.timestampToDateTime() ??
      DateTime.fromMillisecondsSinceEpoch(0);

  @override
  String get md5Hash => nativeInstance.md5Hash ?? '';

  @override
  String? get contentType => nativeInstance.contentType;
}

/// Reference implementation for Admin SDK.
class ReferenceAdminSdk with ReferenceMixin implements Reference {
  /// Bucket instance
  final Bucket bucket;

  /// Path
  final String path;

  /// Constructor
  ReferenceAdminSdk(this.bucket, this.path);

  @override
  Future<String> getDownloadUrl() {
    throw UnsupportedError('getDownloadUrl not supported in Admin SDK');
  }
}
