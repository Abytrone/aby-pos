import 'dart:io';

import 'package:aby_pos/app/core/app_version.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('appVersion is the version in pubspec.yaml', () {
    final line = File('pubspec.yaml').readAsLinesSync().firstWhere((l) => l.startsWith('version:'));
    final version = RegExp(r'version:\s*([0-9]+\.[0-9]+\.[0-9]+)').firstMatch(line)!.group(1);
    expect(appVersion, version, reason: 'Change lib/app/core/app_version.dart when bumping pubspec.yaml');
  });
}
