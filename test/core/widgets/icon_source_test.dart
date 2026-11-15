import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('application UI uses the shared Hugeicons system exclusively', () {
    final forbidden = RegExp(
      r'\b(?:Icons|CupertinoIcons)\s*\.|\b(?:Icon|ImageIcon)\s*\(',
    );
    final violations = <String>[];
    for (final file in Directory(
      'lib',
    ).listSync(recursive: true).whereType<File>()) {
      final path = file.path.replaceAll(r'\', '/');
      if (!path.endsWith('.dart') || path.contains('/gen/')) {
        continue;
      }
      if (forbidden.hasMatch(file.readAsStringSync())) violations.add(path);
    }
    expect(
      violations,
      isEmpty,
      reason: 'Use AppIcons and AppIcon; Material/Cupertino icon families are prohibited.',
    );
  });
}
