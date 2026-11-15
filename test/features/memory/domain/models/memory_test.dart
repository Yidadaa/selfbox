import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:selfbox/core/error/app_failure.dart';
import 'package:selfbox/features/memory/domain/models/memory.dart';

void main() {
  group('MemoryPath.parse', () {
    for (final valid in [
      'user/profile.md',
      'topic/a-topic.md',
      'notes.md',
      'topic/旅行计划.md',
      'user/prefer_food.md',
      'a/b/c/d.md',
    ]) {
      test('accepts "$valid"', () {
        expect(MemoryPath.parse(valid).toNullable()?.value, valid);
      });
    }

    test('trims surrounding whitespace', () {
      expect(
        MemoryPath.parse('  user/profile.md ').toNullable()?.value,
        'user/profile.md',
      );
    });

    for (final invalid in [
      '',
      '../secret.md',
      'user/../../x.md',
      './user/profile.md',
      '/etc/passwd.md',
      r'user\profile.md',
      'user/profile.txt',
      'user/profile',
      'user//profile.md',
      'user/.hidden.md',
      'a/b/c/d/e.md',
      'user/pro:file.md',
      '.md',
    ]) {
      test('rejects "$invalid"', () {
        expect(
          MemoryPath.parse(invalid).getLeft().toNullable(),
          isA<ValidationFailure>(),
        );
      });
    }

    test('rejects paths over the length limit', () {
      final long = '${'a' * MemoryPath.maxLength}.md';
      expect(MemoryPath.parse(long), isA<Left<AppFailure, MemoryPath>>());
    });

    test('exposes folder and file name', () {
      final path = MemoryPath.parse('topic/hiking.md')
          .getOrElse((f) => fail('$f'));
      expect(path.folder, 'topic');
      expect(path.fileName, 'hiking.md');

      final root = MemoryPath.parse('inbox.md').getOrElse((f) => fail('$f'));
      expect(root.folder, isEmpty);
    });
  });

  group('memoryTitle', () {
    final path = MemoryPath.parse('topic/hiking.md')
        .getOrElse((f) => fail('$f'));

    test('uses the first heading of any level', () {
      expect(memoryTitle(path, 'intro\n## 徒步计划\n# Later'), '徒步计划');
    });

    test('falls back to the file name without extension', () {
      expect(memoryTitle(path, 'no heading here'), 'hiking');
      expect(memoryTitle(path, '#\n'), 'hiking');
    });
  });
}
