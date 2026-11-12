# tekartik_firebase_functions_admin_sdk_raw_test

Test fixture, no library: a minimal Firebase project whose single Cloud
Function (`functions/bin/server.dart`, `hello-world`) uses
`package:firebase_functions` alone, run end to end in the Firebase emulator
by `test/emulator_raw_test.dart`.

- Needs the `firebase` cli; without it the test is skipped.
- The test deletes `functions/functions.yaml` first (the emulator
  regenerates it) and starts the functions emulator on the project of
  `.firebaserc` (git ignored). The function uses no other service; a
  function that does must run with a `demo-` project id and the emulators
  of those services, or it reaches the real project.
- `tool/firebase_functions_raw_menu.dart`: a menu to generate or dump
  `functions.yaml` and start the emulator; `tool/compile_dart_function.dart`
  compiles the function for linux x64.

The [skill](skills/tekartik-firebase-functions-admin-sdk-raw-test-setup/SKILL.md)
describes the layout to copy for a new emulator test.
