import 'package:dev_build/shell.dart';

Future<void> main(List<String> args) async {
  var shell = Shell(workingDirectory: 'functions');
  await shell.run(
    'dart compile exe bin/server.dart --target-os=linux --target-arch=x64',
  );
}
