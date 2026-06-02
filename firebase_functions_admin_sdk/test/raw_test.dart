@TestOn('vm')
library;

import 'package:firebase_functions/firebase_functions.dart';
import 'package:test/test.dart';

void main() async {
  test('Request', () {
    // A valid uri absolute is needed (scheme and absolute path)
    var uri = Uri(path: '/test', scheme: 'https');
    // ignore: unused_local_variable
    var request = Request('GET', uri);
  });
}
