import 'package:tekartik_platform_io/context_io.dart';

/// True when run by the Firebase emulator (it sets `FUNCTIONS_EMULATOR`),
/// false on a deployed function and on the web.
bool get isFunctionsEmulator =>
    platformIoOrNull?.environment['FUNCTIONS_EMULATOR'] == 'true';
