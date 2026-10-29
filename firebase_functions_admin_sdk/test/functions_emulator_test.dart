import 'package:tekartik_firebase_functions_admin_sdk/functions_emulator.dart';
import 'package:test/test.dart';

void main() {
  // Allow test on the web
  test('isFunctionsEmulator', () {
    // The tests are never run by the functions emulator.
    expect(isFunctionsEmulator, isFalse);
  });
}
