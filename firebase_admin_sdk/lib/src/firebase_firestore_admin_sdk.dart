import 'dart:async';
import 'dart:typed_data';
import 'package:firebase_admin_sdk/firebase_admin_sdk.dart' as admin_sdk;
import 'package:google_cloud_firestore/google_cloud_firestore.dart' as sdk;
import 'package:tekartik_firebase/firebase_mixin.dart';
import 'package:tekartik_firebase_admin_sdk/firebase_admin_sdk.dart';
import 'package:tekartik_firebase_firestore/firestore_mixin.dart';

import 'firebase_admin_sdk_common.dart';

/// Firestore service implementation for Admin SDK.
class _FirebaseFirestoreServiceAdminSdk
    with FirebaseProductServiceMixin<Firestore>, FirestoreServiceDefaultMixin
    implements FirebaseFirestoreServiceAdminSdk {
  @override
  Firestore firestore(App app) {
    return getInstance(app, () {
      assert(app is FirebaseAppAdminSdk, 'invalid firebase app type');
      var adminApp = app as FirebaseAppAdminSdk;
      // The admin_sdk.FirebaseApp has a firestore() method returning a google_cloud_firestore.Firestore
      var sdkApp =
          (adminApp as dynamic).nativeInstance as admin_sdk.FirebaseApp;
      return FirestoreAdminSdk(this, adminApp, sdkApp.firestore());
    });
  }

  @override
  bool get supportsQuerySelect => true;

  @override
  bool get supportsDocumentSnapshotTime => true;

  @override
  bool get supportsTimestampsInSnapshots => true;

  @override
  bool get supportsTimestamps => true;

  @override
  bool get supportsQuerySnapshotCursor => true;

  @override
  bool get supportsFieldValueArray => true;

  @override
  bool get supportsTrackChanges => false; // google_cloud_firestore is REST based

  @override
  bool get supportsListCollections => true;

  @override
  bool get supportsAggregateQueries => false;

  @override
  bool get supportsVectorValue => true;

  @override
  bool get supportsBlobs => true;
}

FirebaseFirestoreServiceAdminSdk? _firestoreServiceAdminSdk;

/// The firestore service for admin sdk.
/// The firestore service for admin sdk.
FirebaseFirestoreServiceAdminSdk get firestoreServiceAdminSdk =>
    _firestoreServiceAdminSdk ??= _FirebaseFirestoreServiceAdminSdk();

/// Firestore Admin SDK.
abstract class FirebaseFirestoreAdminSdk implements Firestore {}

/// Firestore implementation for Admin SDK.
class FirestoreAdminSdk
    with
        FirebaseAppProductMixin<Firestore>,
        FirestoreDefaultMixin,
        FirestoreMixin
    implements FirebaseFirestoreAdminSdk {
  @override
  final FirebaseFirestoreServiceAdminSdk service;

  /// admin sdk
  final FirebaseAppAdminSdk appAdminSdk;

  /// Native instance
  final sdk.Firestore nativeInstance;

  /// Constructor
  FirestoreAdminSdk(this.service, this.appAdminSdk, this.nativeInstance);

  @override
  App get app => appAdminSdk;

  bool _isCommonValue(Object? value) {
    return (value == null || value is String || value is num || value is bool);
  }

  List<Object?>? _wrapValues(Iterable<Object?>? values) =>
      values?.map((e) => _wrapValue(e)).toList(growable: false);

  Object? _wrapValue(Object? value) {
    if (_isCommonValue(value)) {
      return value;
    } else if (value is Timestamp) {
      return sdk.Timestamp(
        seconds: value.seconds,
        nanoseconds: value.nanoseconds,
      );
    } else if (value is DateTime) {
      return sdk.Timestamp.fromDate(value);
    } else if (value is Iterable) {
      return _wrapValues(value);
    } else if (value is Map) {
      return value.map<String, Object?>(
        (key, value) => MapEntry(key as String, _wrapValue(value)),
      );
    } else if (value is FieldValue) {
      if (FieldValue.delete == value) {
        return sdk.FieldValue.delete;
      } else if (FieldValue.serverTimestamp == value) {
        return sdk.FieldValue.serverTimestamp;
      } else if (value.type == FieldValueType.arrayUnion) {
        return sdk.FieldValue.arrayUnion(value.data as List);
      } else if (value.type == FieldValueType.arrayRemove) {
        return sdk.FieldValue.arrayRemove(value.data as List);
      }
    } else if (value is DocumentReferenceAdminSdk) {
      return value.nativeInstance;
    } else if (value is Blob) {
      return value.data;
    } else if (value is GeoPoint) {
      return sdk.GeoPoint(
        latitude: value.latitude.toDouble(),
        longitude: value.longitude.toDouble(),
      );
    } else if (value is VectorValue) {
      return sdk.VectorValue(value.toArray());
    }

    throw UnsupportedError('not supported $value type ${value.runtimeType}');
  }

  Object? _unwrapValue(Object? nativeValue) {
    if (_isCommonValue(nativeValue)) {
      return nativeValue;
    }
    if (nativeValue is Iterable) {
      if (nativeValue is Uint8List) {
        return Blob(nativeValue);
      }
      return nativeValue
          .map((nativeValue) => _unwrapValue(nativeValue))
          .toList();
    } else if (nativeValue is Map) {
      return nativeValue.map<String, Object?>(
        (key, nativeValue) =>
            MapEntry(key as String, _unwrapValue(nativeValue)),
      );
    } else if (sdk.FieldValue.delete == nativeValue) {
      return FieldValue.delete;
    } else if (sdk.FieldValue.serverTimestamp == nativeValue) {
      return FieldValue.serverTimestamp;
    } else if (nativeValue is sdk.DocumentReference) {
      return _DocumentReferenceAdminSdk(
        this,
        (nativeValue as sdk.DocumentReference<Map<String, Object?>>),
      );
    } else if (nativeValue is sdk.GeoPoint) {
      return GeoPoint(nativeValue.latitude, nativeValue.longitude);
    } else if (nativeValue is sdk.Timestamp) {
      return Timestamp(nativeValue.seconds, nativeValue.nanoseconds);
    } else if (nativeValue is sdk.VectorValue) {
      return VectorValue(nativeValue.toArray());
    } else if (nativeValue is DateTime) {
      // Compat
      return Timestamp.fromDateTime(nativeValue);
    } else {
      throw UnsupportedError(
        'not supported $nativeValue type ${nativeValue.runtimeType}',
      );
    }
  }

  Map<String, Object?> _wrapData(Map<String, Object?> data) => data
      .map<String, Object?>((key, value) => MapEntry(key, _wrapValue(value)));
  Map<String, Object?> _unwrapData(Map<String, Object?> data) => data
      .map<String, Object?>((key, value) => MapEntry(key, _unwrapValue(value)));
  @override
  CollectionReferenceAdminSdk collection(String path) =>
      _wrapCollectionReference(nativeInstance.collection(path));

  @override
  Query collectionGroup(String collectionId) => _wrapQuery(
    nativeInstance.collectionGroup(collectionId),
    orderBy: [],
    collectionReference: collection(collectionId),
  );

  @override
  DocumentReference doc(String path) =>
      _wrapDocumentReference(nativeInstance.doc(path));

  @override
  WriteBatch batch() => _WriteBatchAdminSdk(this, nativeInstance.batch());

  @override
  Future<T> runTransaction<T>(
    FutureOr<T> Function(Transaction transaction) updateFunction,
  ) {
    return nativeInstance.runTransaction((sdkTransaction) async {
      var transaction = _TransactionAdminSdk(this, sdkTransaction);
      return await updateFunction(transaction);
    });
  }

  @override
  Future<List<CollectionReference>> listCollections() async {
    final native = await nativeInstance.listCollections();
    return native.map(_wrapCollectionReference).toList();
  }

  DocumentReference _wrapDocumentReference(
    sdk.DocumentReference<Map<String, Object?>> nativeRef,
  ) => _DocumentReferenceAdminSdk(this, nativeRef);

  _CollectionReferenceAdminSdk _wrapCollectionReference(
    sdk.CollectionReference<Map<String, Object?>> nativeRef,
  ) => _CollectionReferenceAdminSdk(this, nativeRef);

  _QueryAdminSdk _wrapQuery(
    sdk.Query<Map<String, Object?>> nativeQuery, {
    required List<Object> orderBy,
    required CollectionReferenceAdminSdk? collectionReference,
  }) => _QueryAdminSdk(
    this,
    nativeQuery,
    orderBy: orderBy,
    collectionReference: collectionReference,
  );
}

/// Document reference
abstract class DocumentReferenceAdminSdk implements DocumentReference {}

extension on DocumentReferenceAdminSdk {
  _DocumentReferenceAdminSdk get impl => this as _DocumentReferenceAdminSdk;
  sdk.DocumentReference get nativeInstance => impl.nativeInstance;
}

class _DocumentReferenceAdminSdk
    with
        DocumentReferenceDefaultMixin,
        DocumentReferenceMixin,
        PathReferenceMixin
    implements DocumentReferenceAdminSdk, FirestorePathReference {
  final FirestoreAdminSdk firestoreAdminSdk;
  final sdk.DocumentReference<Map<String, Object?>> nativeInstance;

  _DocumentReferenceAdminSdk(this.firestoreAdminSdk, this.nativeInstance);

  @override
  Firestore get firestore => firestoreAdminSdk;

  @override
  String get id => nativeInstance.id;

  @override
  String get path => nativeInstance.path;

  @override
  CollectionReference get parent =>
      firestoreAdminSdk._wrapCollectionReference(nativeInstance.parent);

  @override
  CollectionReference collection(String path) => firestoreAdminSdk
      ._wrapCollectionReference(nativeInstance.collection(path));

  @override
  Future<DocumentSnapshot> get() async {
    var sdkSnapshot = await nativeInstance.get();
    return _DocumentSnapshotAdminSdk(firestoreAdminSdk, sdkSnapshot);
  }

  @override
  Future delete() => nativeInstance.delete();

  @override
  Future set(Map<String, Object?> data, [SetOptions? options]) =>
      nativeInstance.set(
        firestoreAdminSdk._wrapData(data),
        options: _unwrapSetOptions(options),
      );

  @override
  Future update(Map<String, Object?> data) =>
      nativeInstance.update(firestoreAdminSdk._wrapData(data));

  @override
  Future<List<CollectionReference>> listCollections() async {
    return (await nativeInstance.listCollections())
        .map(
          (nativeInstance) =>
              _CollectionReferenceAdminSdk(firestoreAdminSdk, nativeInstance),
        )
        .toList();
  }

  @override
  Stream<DocumentSnapshot> onSnapshot({bool includeMetadataChanges = false}) =>
      throw UnsupportedError('onSnapshot not supported in Admin SDK (REST)');
}

class _QueryAdminSdk with QueryMixin implements Query {
  final List<Object> _orderByKey;
  final FirestoreAdminSdk firestoreAdminSdk;
  final sdk.Query<Map<String, Object?>> nativeInstance;
  _CollectionReferenceAdminSdk get collectionReference => _collectionReference!;
  final _CollectionReferenceAdminSdk? _collectionReference;
  _QueryAdminSdk(
    this.firestoreAdminSdk,
    this.nativeInstance, {
    required List<Object> orderBy,
    required CollectionReferenceAdminSdk? collectionReference,
  }) : _collectionReference =
           collectionReference as _CollectionReferenceAdminSdk?,
       _orderByKey = orderBy;

  @override
  Firestore get firestore => firestoreAdminSdk;

  @override
  Future<QuerySnapshot> get() async {
    var sdkSnapshot = await nativeInstance.get();
    return _QuerySnapshotAdminSdk(firestoreAdminSdk, sdkSnapshot);
  }

  @override
  Stream<QuerySnapshot> onSnapshot({bool includeMetadataChanges = false}) =>
      throw UnsupportedError('onSnapshot not supported in Admin SDK (REST)');

  @override
  Future<int> count() async => (await nativeInstance.count().get()).count!;

  @override
  Query limit(int limit) => _wrapQuery(nativeInstance.limit(limit));

  @override
  Query orderBy(String key, {bool? descending}) => _wrapQuery(
    nativeInstance.orderBy(key, descending: descending ?? false),
    addedOrderKey: key,
  );

  @override
  Query select(List<String> keyPaths) => _wrapQuery(
    nativeInstance.select(keyPaths.map((k) => sdk.FieldPath.from(k)).toList()),
  );

  _QueryAdminSdk _wrapQuery(
    sdk.Query<Map<String, Object?>> nativeInstance, {
    String? addedOrderKey,
  }) {
    return firestoreAdminSdk._wrapQuery(
      nativeInstance,
      orderBy: [..._orderByKey, ?addedOrderKey],
      collectionReference: collectionReference,
    );
  }

  Object? _wrapValue(Object? value) => firestoreAdminSdk._wrapValue(value);
  @override
  Query where(
    String fieldPath, {
    isEqualTo,
    isLessThan,
    isLessThanOrEqualTo,
    isGreaterThan,
    isGreaterThanOrEqualTo,
    arrayContains,
    List<Object?>? arrayContainsAny,
    List<Object?>? whereIn,
    bool? isNull,
  }) {
    if (isEqualTo != null) {
      return _wrapQuery(
        nativeInstance.where(
          fieldPath,
          sdk.WhereFilter.equal,
          _wrapValue(isEqualTo),
        ),
      );
    } else if (isLessThan != null) {
      return _wrapQuery(
        nativeInstance.where(
          fieldPath,
          sdk.WhereFilter.lessThan,
          _wrapValue(isLessThan),
        ),
      );
    } else if (isLessThanOrEqualTo != null) {
      return _wrapQuery(
        nativeInstance.where(
          fieldPath,
          sdk.WhereFilter.lessThanOrEqual,
          _wrapValue(isLessThanOrEqualTo),
        ),
      );
    } else if (isGreaterThan != null) {
      return _wrapQuery(
        nativeInstance.where(
          fieldPath,
          sdk.WhereFilter.greaterThan,
          _wrapValue(isGreaterThan),
        ),
      );
    } else if (isGreaterThanOrEqualTo != null) {
      return _wrapQuery(
        nativeInstance.where(
          fieldPath,
          sdk.WhereFilter.greaterThanOrEqual,
          _wrapValue(isGreaterThanOrEqualTo),
        ),
      );
    } else if (arrayContains != null) {
      return _wrapQuery(
        nativeInstance.where(
          fieldPath,
          sdk.WhereFilter.arrayContains,
          _wrapValue(arrayContains),
        ),
      );
    } else if (arrayContainsAny != null) {
      return _wrapQuery(
        nativeInstance.where(
          fieldPath,
          sdk.WhereFilter.arrayContainsAny,
          _wrapValue(arrayContainsAny),
        ),
      );
    } else if (whereIn != null) {
      return _wrapQuery(
        nativeInstance.where(
          fieldPath,
          sdk.WhereFilter.isIn,
          _wrapValue(whereIn),
        ),
      );
    } else if (isNull != null) {
      return _wrapQuery(
        nativeInstance.where(fieldPath, sdk.WhereFilter.equal, null),
      );
    }
    return this;
  }

  List<Object> _wrapBoundaryValues(List? values) {
    if (values == null) {
      throw ArgumentError(
        'values must be provided for all orderBy fields: $_orderByKey',
      );
    }
    final wrapped = <Object>[];
    if (values.length < _orderByKey.length) {
      throw ArgumentError(
        'values must be provided for all orderBy fields: $_orderByKey',
      );
    }
    for (var (index, key) in _orderByKey.indexed) {
      var value = values.elementAt(index);
      // Invalid argument(s): When ordering with FieldPath.documentId(), the cursor must be a DocumentReference.
      if (key == firestoreNameFieldPath || key == sdk.FieldPath.documentId) {
        if (value is String) {
          value = collectionReference.doc(value);
        } else if (value is DocumentSnapshot) {
          value = value.ref;
        }
      }
      wrapped.add(firestoreAdminSdk._wrapValue(value)!);
    }
    return wrapped;
  }

  @override
  Query startAt({DocumentSnapshot? snapshot, List? values}) => _wrapQuery(
    (snapshot != null)
        ? nativeInstance.startAtDocument(snapshot._sdk.nativeInstance)
        : nativeInstance.startAt(_wrapBoundaryValues(values)),
  );

  @override
  Query startAfter({DocumentSnapshot? snapshot, List? values}) => _wrapQuery(
    (snapshot != null)
        ? nativeInstance.startAfterDocument(snapshot._sdk.nativeInstance)
        : nativeInstance.startAfter(_wrapBoundaryValues(values)),
  );

  @override
  Query endAt({DocumentSnapshot? snapshot, List? values}) => _wrapQuery(
    (snapshot != null)
        ? nativeInstance.endAtDocument(snapshot._sdk.nativeInstance)
        : nativeInstance.endAt(_wrapBoundaryValues(values)),
  );

  @override
  Query endBefore({DocumentSnapshot? snapshot, List? values}) => _wrapQuery(
    (snapshot != null)
        ? nativeInstance.endBeforeDocument(snapshot._sdk.nativeInstance)
        : nativeInstance.endBefore(_wrapBoundaryValues(values)),
  );

  @override
  AggregateQuery aggregate(List<AggregateField> aggregateFields) {
    throw UnimplementedError('aggregate not supported in Admin SDK');
  }

  @override
  QueryMixin clone() => _wrapQuery(nativeInstance);

  @override
  Stream<int> onCount() => throw UnsupportedError('onCount not supported');

  @override
  Query orderById({bool? descending}) => _wrapQuery(
    nativeInstance.orderBy(
      sdk.FieldPath.documentId,
      descending: descending ?? false,
    ),
    addedOrderKey: firestoreNameFieldPath,
  );
}

/// Collection reference
abstract class CollectionReferenceAdminSdk implements CollectionReference {}

class _CollectionReferenceAdminSdk extends _QueryAdminSdk
    with CollectionReferenceMixin, PathReferenceMixin
    implements CollectionReferenceAdminSdk, FirestorePathReference {
  _CollectionReferenceAdminSdk(
    super.firestoreAdminSdk,
    sdk.CollectionReference<Map<String, Object?>> super.nativeInstance,
  ) : super(orderBy: [], collectionReference: null);

  @override
  _CollectionReferenceAdminSdk get collectionReference => this;

  @override
  sdk.CollectionReference<Map<String, Object?>> get nativeInstance =>
      super.nativeInstance as sdk.CollectionReference<Map<String, Object?>>;

  @override
  String get id => nativeInstance.id;

  @override
  String get path => nativeInstance.path;

  @override
  DocumentReference doc([String? path]) =>
      firestoreAdminSdk._wrapDocumentReference(nativeInstance.doc(path ?? ''));

  @override
  Future<DocumentReference> add(Map<String, Object?> data) async {
    var sdkDocRef = await nativeInstance.add(data);
    return firestoreAdminSdk._wrapDocumentReference(sdkDocRef);
  }

  @override
  DocumentReference? get parent {
    final nativeParent = nativeInstance.parent;
    if (nativeParent == null) return null;
    return firestoreAdminSdk._wrapDocumentReference(nativeParent);
  }
}

class _QuerySnapshotAdminSdk implements QuerySnapshot {
  final FirestoreAdminSdk firestoreAdminSdk;
  final sdk.QuerySnapshot<Map<String, Object?>> nativeInstance;

  _QuerySnapshotAdminSdk(this.firestoreAdminSdk, this.nativeInstance);

  @override
  List<DocumentSnapshot> get docs => nativeInstance.docs
      .where((doc) => doc.exists)
      .map(
        (sdkSnapshot) =>
            _DocumentSnapshotAdminSdk(firestoreAdminSdk, sdkSnapshot),
      )
      .toList();

  @override
  List<DocumentChange> get documentChanges =>
      throw UnsupportedError('documentChanges not supported in Admin SDK');
}

/// Document snapshot impl
extension DocumentSnapshotAdminSdkExt on DocumentSnapshot {
  /// Sdk implementation
  _DocumentSnapshotAdminSdk get _sdk => this as _DocumentSnapshotAdminSdk;
}

/// Needed for query
final _kUseEmptyDataHack = true; // devWarning(false);

class _DocumentSnapshotAdminSdk
    with DocumentSnapshotMixin
    implements DocumentSnapshot {
  final FirestoreAdminSdk firestoreAdminSdk;
  final sdk.DocumentSnapshot<Map<String, Object?>> nativeInstance;

  _DocumentSnapshotAdminSdk(this.firestoreAdminSdk, this.nativeInstance);

  late final _data = () {
    var isExisting = exists;
    if (!isExisting) {
      throw StateError('Document does not exist'); // to report
    }
    // workaround empty data
    Map<String, Object?>? rawData;

    try {
      rawData = nativeInstance.data();
    } catch (e) {
      if (_kUseEmptyDataHack) {
        if (isExisting) {
          // print('error reading data: $e');
          // error reading data: Bad state: The data in a QueryDocumentSnapshot should always exist.
          // to report
          rawData = <String, Object?>{};
        } else {
          rethrow;
        }
      } else {
        rethrow;
      }
    }

    return firestoreAdminSdk._unwrapData(rawData ?? <String, Object?>{});
  }();
  @override
  Map<String, Object?> get data => _data;

  @override
  bool get exists => nativeInstance.exists;

  @override
  DocumentReference get ref =>
      firestoreAdminSdk._wrapDocumentReference(nativeInstance.ref);

  @override
  Timestamp? get updateTime => _wrapTimestamp(nativeInstance.updateTime);

  @override
  Timestamp? get createTime => _wrapTimestamp(nativeInstance.createTime);
}

class _WriteBatchAdminSdk implements WriteBatch {
  final FirestoreAdminSdk firestoreAdminSdk;
  final sdk.WriteBatch nativeInstance;
  _WriteBatchAdminSdk(this.firestoreAdminSdk, this.nativeInstance);

  @override
  Future commit() => nativeInstance.commit();

  @override
  void delete(DocumentReference ref) =>
      nativeInstance.delete((ref as _DocumentReferenceAdminSdk).nativeInstance);

  @override
  void set(
    DocumentReference ref,
    Map<String, Object?> data, [
    SetOptions? options,
  ]) => nativeInstance.set(
    (ref as _DocumentReferenceAdminSdk).nativeInstance,
    firestoreAdminSdk._wrapData(data),
    options: _unwrapSetOptions(options),
  );

  @override
  void update(DocumentReference ref, Map<String, Object?> data) =>
      nativeInstance
          .update((ref as _DocumentReferenceAdminSdk).nativeInstance, {
            for (final e in data.entries)
              sdk.FieldPath.from(e.key): firestoreAdminSdk._wrapValue(e.value),
          });
}

class _TransactionAdminSdk implements Transaction {
  final FirestoreAdminSdk firestoreAdminSdk;
  final sdk.Transaction nativeInstance;

  _TransactionAdminSdk(this.firestoreAdminSdk, this.nativeInstance);

  @override
  void delete(DocumentReference documentRef) => nativeInstance.delete(
    (documentRef as _DocumentReferenceAdminSdk).nativeInstance
        as sdk.DocumentReference<Map<String, dynamic>>,
  );

  @override
  Future<DocumentSnapshot> get(DocumentReference documentRef) async {
    var sdkSnapshot = await nativeInstance.get(
      (documentRef as _DocumentReferenceAdminSdk).nativeInstance,
    );
    return _DocumentSnapshotAdminSdk(firestoreAdminSdk, sdkSnapshot);
  }

  @override
  void set(
    DocumentReference documentRef,
    Map<String, Object?> data, [
    SetOptions? options,
  ]) => nativeInstance.set(
    (documentRef as _DocumentReferenceAdminSdk).nativeInstance,
    firestoreAdminSdk._wrapData(data),
    options: _unwrapSetOptions(options),
  );

  @override
  void update(DocumentReference documentRef, Map<String, Object?> data) =>
      nativeInstance.update(
        (documentRef as _DocumentReferenceAdminSdk).nativeInstance,
        firestoreAdminSdk._wrapData(data),
      );
}

sdk.SetOptions? _unwrapSetOptions(SetOptions? options) =>
    options?.merge == true ? const sdk.SetOptions.merge() : null;

Timestamp? _wrapTimestamp(sdk.Timestamp? ts) =>
    ts == null ? null : Timestamp(ts.seconds, ts.nanoseconds);
