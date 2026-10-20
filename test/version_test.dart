import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/app/version.dart';

void main() {
  test('the version shown in the app matches pubspec.yaml', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final match = RegExp(r'^version:\s*(\S+)\+(\d+)\s*$', multiLine: true).firstMatch(pubspec);

    expect(match, isNotNull, reason: 'pubspec.yaml needs a "version: x.y.z+N" line');
    expect(appVersion, match!.group(1), reason: 'Update lib/app/version.dart to match pubspec.yaml');
    expect(appBuildNumber, match.group(2), reason: 'Update lib/app/version.dart to match pubspec.yaml');
  });
}
