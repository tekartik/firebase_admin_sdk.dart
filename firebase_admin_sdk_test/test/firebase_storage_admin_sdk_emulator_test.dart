@TestOn('vm')
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

// The zone environment key of the sdk (internal, used by its own storage
// tests): the only way to point a storage at the emulator without setting
// the process environment before the test starts.
// ignore: implementation_imports, invalid_use_of_internal_member
import 'package:firebase_admin_sdk/src/app.dart' show envSymbol;
import 'package:http/http.dart' as http;
import 'package:tekartik_firebase_admin_sdk/firebase_admin_sdk.dart';
import 'package:tekartik_firebase_admin_sdk/firebase_storage_admin_sdk.dart';
import 'package:tekartik_firebase_emulator/firebase_emulator.dart';
import 'package:tekartik_firebase_storage_test/storage_test.dart';
import 'package:test/test.dart';

/// Needs `emulator/.firebaserc` (git ignored), skipped otherwise.
var _emulatorService = FirebaseEmulatorService(path: 'emulator');

/// The storage emulator host, see `emulator/firebase.json`.
const _storageEmulatorHost = '127.0.0.1:9199';

Future<void> main() async {
  if (!await _emulatorService.isSupported()) {
    test('not_supported', () {}, skip: 'firebase emulator is not supported');
    return;
  }

  final projectId = await _emulatorService.getProjectId();
  var storageBucket = '$projectId.appspot.com';
  late FirebaseEmulator emulator;

  group('storage_admin_sdk_emulator', () {
    setUpAll(() async {
      emulator = await _emulatorService.start(
        options: FirebaseEmulatorOptions(
          projectId: projectId,
          onlyStorage: true,
          debug: false,
        ),
      );
    });

    tearDownAll(() async {
      await emulator.stop();
    });

    // The admin sdk reads FIREBASE_STORAGE_EMULATOR_HOST (from the zone
    // environment first) when the storage is created, and sets the process
    // wide STORAGE_EMULATOR_HOST that the cloud storage client reads when
    // the first bucket is created. Any other storage created in the process
    // resets it, so both are created here, one after the other.
    late FirebaseApp app;
    late FirebaseStorage storage;
    runZoned(
      () {
        app = firebaseAdminSdk.initializeApp(
          options: FirebaseAppOptions(
            projectId: projectId,
            storageBucket: storageBucket,
          ),
          name: 'storage_emulator',
        );
        storage = firebaseStorageServiceAdminSdk.storage(app);
        storage.bucket(storageBucket);
      },
      zoneValues: {
        // ignore: invalid_use_of_internal_member
        envSymbol: {
          ...Platform.environment,
          'FIREBASE_STORAGE_EMULATOR_HOST': _storageEmulatorHost,
        },
      },
    );

    tearDownAll(() async {
      await app.delete();
    });

    runStorageAppTests(
      app,
      storageService: firebaseStorageServiceAdminSdk,
      storageOptions: TestStorageOptions(
        bucket: storageBucket,
        skipDefaultBucketExists: true,
      ),
    );

    group('cache_control', () {
      /// Downloads [file] from the emulator, as a visitor would.
      Future<http.Response> download(File file) => http.get(
        Uri.parse(
          'http://$_storageEmulatorHost/download/storage/v1/b/$storageBucket'
          '/o/${Uri.encodeComponent(file.name)}?alt=media',
        ),
      );

      test('served', () async {
        var bucket = storage.bucket(storageBucket);
        // A tekaly export and its meta, as the publish step writes them.
        var exportFile = bucket.file('test/cache_control/export_1.jsonl');
        var metaFile = bucket.file('test/cache_control/export_meta.json');
        await exportFile.upload(
          utf8.encode('{"tekaly_export":1}\n'),
          options: StorageUploadFileOptions(
            contentType: 'application/x-ndjson',
            cacheControl: 'public, max-age=31536000, immutable',
          ),
        );
        await metaFile.upload(
          utf8.encode('{"lastChangeId":1}'),
          options: StorageUploadFileOptions(
            contentType: 'application/json',
            cacheControl: 'no-cache',
          ),
        );

        var response = await download(exportFile);
        expect(response.statusCode, 200);
        expect(
          response.headers['cache-control'],
          'public, max-age=31536000, immutable',
        );
        expect(response.body, '{"tekaly_export":1}\n');

        response = await download(metaFile);
        expect(response.statusCode, 200);
        expect(response.headers['cache-control'], 'no-cache');
      });

      test('listed', () async {
        var bucket = storage.bucket(storageBucket);
        var file = bucket.file('test/cache_control_listed/file.txt');
        await file.upload(
          utf8.encode('listed'),
          options: StorageUploadFileOptions(cacheControl: 'no-cache'),
        );
        var response = await bucket.getFiles(
          GetFilesOptions(prefix: 'test/cache_control_listed/'),
        );
        var listed = response.files.single;
        // Listed files carry their metadata, no extra request needed.
        expect(listed.metadata!.cacheControl, 'no-cache');
        expect(listed.metadata!.size, 6);
      });
    });
  }, timeout: const Timeout(Duration(minutes: 5)));
}
