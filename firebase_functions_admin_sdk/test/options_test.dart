import 'package:firebase_functions/firebase_functions.dart' as fn;
import 'package:tekartik_firebase_functions/firebase_functions.dart';
import 'package:tekartik_firebase_functions_admin_sdk/src/functions_admin_sdk.dart';
import 'package:test/test.dart';

Future<void> main() async {
  test('supported region', () {
    expect(wrapRegion(regionBelgium)!.value(), fn.SupportedRegion.europeWest1);
    expect(
      wrapRegion(regionUsCentral1)!.value(),
      equals(fn.SupportedRegion.usCentral1),
    );
  });
}
