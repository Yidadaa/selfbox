import 'dart:async';

import 'package:fpdart/fpdart.dart';

import '../../features/memory/domain/models/memory.dart';
import '../../features/memory/domain/repositories/memory_repository.dart';
import '../../features/memory/domain/services/unified_diff.dart';
import '../error/app_failure.dart';

/// In-memory [MemoryRepository] for widget/provider tests, where real file
/// I/O never completes inside fake-async zones. Same rules as the file one.
class FakeMemoryRepository implements MemoryRepository {
  FakeMemoryRepository({
    Map<String, String> seed = const {},
    DateTime Function()? clock,
  }) : _clock = clock ?? (() => DateTime(2026, 11, 12, 9)) {
    for (final MapEntry(:key, :value) in seed.entries) {
      _files[MemoryPath.parse(key).getOrElse((f) => throw f)] = (
        content: value,
        at: _clock(),
      );
    }
  }

  final DateTime Function() _clock;
  final _files = <MemoryPath, ({String content, DateTime at})>{};
  final _changes = StreamController<void>.broadcast();

  @override
  TaskEither<AppFailure, Unit> clearAll() {
    _files.clear();
    _changes.add(null);
    return TaskEither.right(unit);
  }

  String? contentOf(String path) =>
      _files[MemoryPath.parse(path).getOrElse((f) => throw f)]?.content;

  List<MemoryEntry> _entries() => [
    for (final MapEntry(key: path, value: file) in _files.entries)
      MemoryEntry(
        path: path,
        updatedAt: file.at,
        sizeBytes: file.content.length,
        title: memoryTitle(path, file.content),
      ),
  ]..sort((a, b) => a.path.value.compareTo(b.path.value));

  @override
  Stream<List<MemoryEntry>> watchEntries() async* {
    yield _entries();
    await for (final _ in _changes.stream) {
      yield _entries();
    }
  }

  @override
  TaskEither<AppFailure, List<MemoryEntry>> list() =>
      TaskEither.right(_entries());

  @override
  TaskEither<AppFailure, Option<MemoryFile>> read(MemoryPath path) =>
      TaskEither.right(
        Option.fromNullable(_files[path]).map(
          (f) => MemoryFile(path: path, content: f.content, updatedAt: f.at),
        ),
      );

  TaskEither<AppFailure, MemoryFile> _put(MemoryPath path, String content) {
    _files[path] = (content: content, at: _clock());
    _changes.add(null);
    return TaskEither.right(
      MemoryFile(path: path, content: content, updatedAt: _clock()),
    );
  }

  @override
  TaskEither<AppFailure, MemoryFile> create(MemoryPath path, String content) {
    if (_files.containsKey(path)) {
      return TaskEither.left(
        AppFailure.validation(message: '${path.value} already exists'),
      );
    }
    return _put(
      path,
      content.isEmpty || content.endsWith('\n') ? content : '$content\n',
    );
  }

  @override
  TaskEither<AppFailure, MemoryFile> patch(MemoryPath path, String diff) {
    final current = _files[path];
    if (current == null) {
      return TaskEither.left(
        AppFailure.validation(message: '${path.value} does not exist'),
      );
    }
    return TaskEither.fromEither(applyUnifiedDiff(current.content, diff))
        .flatMap((updated) => _put(path, updated));
  }

  @override
  TaskEither<AppFailure, Unit> delete(MemoryPath path) {
    if (_files.remove(path) == null) {
      return TaskEither.left(
        AppFailure.validation(message: '${path.value} does not exist'),
      );
    }
    _changes.add(null);
    return TaskEither.right(unit);
  }

  @override
  TaskEither<AppFailure, List<MemorySearchHit>> search(
    String keywords, {
    int limit = 30,
  }) {
    final terms = keywords
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((t) => t.isNotEmpty)
        .toList();
    if (terms.isEmpty) return TaskEither.right(const []);
    final hits = <MemorySearchHit>[
      for (final entry in _entries())
        for (final (i, line)
            in (_files[entry.path]?.content ?? '').split('\n').indexed)
          if (line.trim().isNotEmpty &&
              terms.every('${entry.path.value} $line'.toLowerCase().contains))
            MemorySearchHit(path: entry.path, line: i + 1, text: line),
    ];
    return TaskEither.right(hits.take(limit).toList());
  }
}
