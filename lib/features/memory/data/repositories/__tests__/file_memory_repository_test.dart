import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:path/path.dart' as p;
import 'package:selfbox/core/error/app_failure.dart';
import 'package:selfbox/core/testing/temp_storage.dart';
import 'package:selfbox/features/memory/data/repositories/file_memory_repository.dart';
import 'package:selfbox/features/memory/domain/models/memory.dart';

MemoryPath _path(String raw) =>
    MemoryPath.parse(raw).getOrElse((f) => fail('$f'));

T _ok<T>(Either<AppFailure, T> result) =>
    result.getOrElse((f) => fail('expected success, got $f'));

FileMemoryRepository _repo() =>
    FileMemoryRepository(createTempAppPaths().memory);

void main() {
  group('FileMemoryRepository', () {
    test('lists nothing before the memory folder exists', () async {
      expect(_ok(await _repo().list().run()), isEmpty);
    });

    test('create writes the file with a trailing newline', () async {
      final repo = _repo();
      final file = _ok(
        await repo.create(_path('user/profile.md'), '# Profile').run(),
      );

      expect(file.content, '# Profile\n');
      expect(
        File(p.join(repo.root.path, 'user', 'profile.md')).readAsStringSync(),
        '# Profile\n',
      );
    });

    test('create refuses to overwrite an existing file', () async {
      final repo = _repo();
      await repo.create(_path('user/profile.md'), 'a').run();
      final again = await repo.create(_path('user/profile.md'), 'b').run();

      expect(again.getLeft().toNullable(), isA<ValidationFailure>());
      expect(
        _ok(await repo.read(_path('user/profile.md')).run())
            .toNullable()
            ?.content,
        'a\n',
      );
    });

    test('read returns none for a missing file', () async {
      expect(_ok(await _repo().read(_path('x.md')).run()), isA<None>());
    });

    test('patch applies a unified diff to the stored content', () async {
      final repo = _repo();
      await repo.create(_path('user/prefer.md'), '# 偏好\n- 咖啡：美式\n').run();

      final file = _ok(
        await repo
            .patch(_path('user/prefer.md'), '@@ @@\n-- 咖啡：美式\n+- 咖啡：拿铁\n')
            .run(),
      );
      expect(file.content, '# 偏好\n- 咖啡：拿铁\n');
    });

    test('a mismatched patch fails and leaves the file untouched', () async {
      final repo = _repo();
      await repo.create(_path('a.md'), 'one\n').run();

      final result = await repo.patch(_path('a.md'), '@@ @@\n-two\n+2\n').run();
      expect(result.getLeft().toNullable(), isA<ValidationFailure>());
      expect(
        _ok(await repo.read(_path('a.md')).run()).toNullable()?.content,
        'one\n',
      );
    });

    test('patching a missing file fails', () async {
      final result = await _repo().patch(_path('a.md'), '@@ @@\n+x\n').run();
      expect(result.getLeft().toNullable(), isA<ValidationFailure>());
    });

    test('list is sorted by path and titled from headings', () async {
      final repo = _repo();
      await repo.create(_path('topic/hiking.md'), '# 爬山\n').run();
      await repo.create(_path('user/profile.md'), 'no heading').run();

      final entries = _ok(await repo.list().run());
      expect(entries.map((e) => e.path.value), [
        'topic/hiking.md',
        'user/profile.md',
      ]);
      expect(entries.map((e) => e.title), ['爬山', 'profile']);
      expect(entries.first.sizeBytes, greaterThan(0));
    });

    test('list ignores files with unsupported names', () async {
      final repo = _repo();
      await repo.create(_path('ok.md'), 'x').run();
      File(p.join(repo.root.path, 'notes.txt')).writeAsStringSync('x');
      File(p.join(repo.root.path, '.DS_Store')).writeAsStringSync('x');

      expect(_ok(await repo.list().run()).map((e) => e.path.value), ['ok.md']);
    });

    test('delete removes the file and prunes empty folders', () async {
      final repo = _repo();
      await repo.create(_path('topic/sub/a.md'), 'x').run();
      await repo.create(_path('topic/b.md'), 'x').run();

      _ok(await repo.delete(_path('topic/sub/a.md')).run());
      expect(
        Directory(p.join(repo.root.path, 'topic', 'sub')).existsSync(),
        isFalse,
      );
      expect(Directory(p.join(repo.root.path, 'topic')).existsSync(), isTrue);

      _ok(await repo.delete(_path('topic/b.md')).run());
      expect(Directory(p.join(repo.root.path, 'topic')).existsSync(), isFalse);
      expect(repo.root.existsSync(), isTrue);
    });

    test('deleting a missing file fails', () async {
      final result = await _repo().delete(_path('nope.md')).run();
      expect(result.getLeft().toNullable(), isA<ValidationFailure>());
    });

    test('watchEntries emits now and after every write', () async {
      final repo = _repo();
      final seen = <List<String>>[];
      final sub = repo.watchEntries().listen(
        (entries) => seen.add(entries.map((e) => e.path.value).toList()),
      );
      addTearDown(sub.cancel);

      await _waitFor(() => seen.isNotEmpty);
      await repo.create(_path('a.md'), 'x').run();
      await _waitFor(() => seen.last.length == 1);
      await repo.delete(_path('a.md')).run();
      await _waitFor(() => seen.last.isEmpty && seen.length >= 3);

      expect(seen.first, isEmpty);
      expect(seen[1], ['a.md']);
    });

    test('concurrent patches are serialized, not lost', () async {
      final repo = _repo();
      await repo.create(_path('log.md'), '# Log\n').run();

      await Future.wait([
        repo.patch(_path('log.md'), '@@ @@\n # Log\n+- a\n').run(),
        repo.patch(_path('log.md'), '@@ @@\n # Log\n+- b\n').run(),
      ]);
      final content = _ok(await repo.read(_path('log.md')).run())
          .toNullable()
          ?.content;
      expect(content, contains('- a'));
      expect(content, contains('- b'));
    });

    test(
      'search matches every keyword, case-insensitively, with line numbers',
      () async {
        final repo = _repo();
        await repo
            .create(
              _path('user/prefer.md'),
              '# Prefer\n- Coffee: latte\n- Tea: green\n',
            )
            .run();
        await repo
            .create(_path('topic/coffee.md'), '# Beans\n- origin: Yunnan\n')
            .run();

        final hits = _ok(await repo.search('COFFEE latte').run());
        expect(hits.single.path.value, 'user/prefer.md');
        expect(hits.single.line, 2);

        final byPath = _ok(await repo.search('coffee yunnan').run());
        expect(byPath.single.path.value, 'topic/coffee.md');
      },
    );

    test('blank searches return nothing', () async {
      expect(_ok(await _repo().search('  ').run()), isEmpty);
    });
  });
}

Future<void> _waitFor(bool Function() condition) async {
  for (var i = 0; i < 200 && !condition(); i++) {
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
  expect(condition(), isTrue, reason: 'condition not met in time');
}
