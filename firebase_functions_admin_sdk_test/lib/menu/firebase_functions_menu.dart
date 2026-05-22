import 'dart:io';
import 'package:dev_build/shell.dart';
import 'package:path/path.dart';
import 'package:tekartik_app_dev_menu/dev_menu.dart';
import 'package:tekartik_firebase_emulator/firebase_emulator.dart';

/// App helper for managing Firebase emulator within the dev menu.
class App {
  /// The path to the firebase project.
  final String path;

  /// The current running emulator instance.
  FirebaseEmulator? emulator;

  /// Options for starting the emulator.
  FirebaseEmulatorOptions? options;

  late final _emulatorService = FirebaseEmulatorService(path: path);

  /// Create an app helper.
  App({required this.path});

  /// Starts the Firebase emulator, stopping any existing one first.
  Future<FirebaseEmulator?> startFirebaseEmulator() async {
    await emulator?.stop();
    var firebaseEmulator = await _emulatorService.start(options: options);
    emulator = firebaseEmulator;
    return emulator;
  }

  /// Returns true if the emulator is supported on this platform.
  Future<bool> isEmulatorSupported() => _emulatorService.isSupported();
}

Future<void> main(List<String> args) async {
  await firebaseFunctionsMenuMain(args);
}

/// Main menu
Future<void> firebaseFunctionsMenuMain(List<String> args) async {
  var app = App(path: '.');
  await mainMenuUniversal(args, () {
    var file = File(join('functions', 'functions.yaml'));
    item('delete functions.yaml', () async {
      // Force re-generation of functions.yaml

      if (file.existsSync()) {
        await file.delete();
      }
    });
    item('generate functions.yaml', () async {
      var shell = Shell();
      await shell.run('firebase emulators:exec --only functions "exit 0"');
    });
    item('Dump functions.yaml', () async {
      var content = await file.readAsString();
      write(content);
    });
    item('emulator is supported', () async {
      write('isSupported: ${await app.isEmulatorSupported()}');
    });
    item('start firebase emulator', () async {
      await app.startFirebaseEmulator();
    });
    item('stop firebase emulator', () async {
      await app.emulator?.stop();
    });
  });
}
