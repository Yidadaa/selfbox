import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:fpdart/fpdart.dart';
import 'package:path/path.dart' as p;

import '../../../../core/error/app_failure.dart';
import '../../domain/models/memory.dart';
import '../../domain/repositories/memory_repository.dart';
import '../../domain/services/unified_diff.dart';

/// Memory files stored as plain markdown under [root].
class FileMemoryRepository implements MemoryRepository {
  FileMemoryRepository(this.root);

  final Directory root;
  final _changes = StreamController<void>.broadcast();

  /// Writes are serialized so two agent tool calls cannot interleave a
  /// read-patch-write cycle on the same file.
  Future<void> _queue = Future.value();

  @override
  TaskEither<AppFailure, Unit> clearAll() => _write(() async {
    if (await root.exists()) await root.delete(recursive: true);
    return unit;
  });

  static AppFailure _ioFailure(Object error, StackTrace _) => switch (error) {
    final AppFailure failure => failure,
    _ => AppFailure.database(message: error.toString()),
  };

  File _file(MemoryPath path) => File(p.joinAll([root.path, ...path.segments]));

  TaskEither<AppFailure, T> _read<T>(Future<T> Function() body) =>
      TaskEither.tryCatch(body, _ioFailure);

  TaskEither<AppFailure, T> _write<T>(Future<T> Function() body) =>
      TaskEither.tryCatch(() {
        final result = _queue.then((_) => body());
        _queue = result.then((_) {}, onError: (_) {});
        return result;
      }, _ioFailure).map((value) {
        _changes.add(null);
        return value;
      });

  @override
  Stream<List<MemoryEntry>> watchEntries() {
    StreamSubscription<void>? changes;
    // Re-reads are chained so a slow listing can never overtake a newer one.
    var pending = Future<void>.value();
    late final StreamController<List<MemoryEntry>> controller;
    void refresh() {
      pending = pending.then((_) async {
        if (controller.isClosed) return;
        try {
          final entries = await _entries();
          if (!controller.isClosed) controller.add(entries);
        } on Object catch (error, stack) {
          if (!controller.isClosed) {
            controller.addError(_ioFailure(error, stack), stack);
          }
        }
      });
    }

    controller = StreamController<List<MemoryEntry>>(
      onListen: () {
        changes = _changes.stream.listen((_) => refresh());
        refresh();
      },
      onCancel: () async {
        await changes?.cancel();
        await controller.close();
      },
    );
    return controller.stream;
  }

  @override
  TaskEither<AppFailure, List<MemoryEntry>> list() => _read(_entries);

  Future<List<MemoryEntry>> _entries() async {
    if (!await root.exists()) return const [];
    final entries = <MemoryEntry>[];
    await for (final entity in root.list(recursive: true)) {
      if (entity is! File) continue;
      final relative = p
          .relative(entity.path, from: root.path)
          .replaceAll(r'\', '/');
      // Files placed by hand with unsupported names are not exposed.
      final path = MemoryPath.parse(relative).toNullable();
      if (path == null) continue;
      final stat = await entity.stat();
      entries.add(
        MemoryEntry(
          path: path,
          updatedAt: stat.modified,
          sizeBytes: stat.size,
          title: memoryTitle(path, await entity.readAsString()),
        ),
      );
    }
    entries.sort((a, b) => a.path.value.compareTo(b.path.value));
    return List.unmodifiable(entries);
  }

  @override
  TaskEither<AppFailure, Option<MemoryFile>> read(MemoryPath path) =>
      _read(() async {
        final file = _file(path);
        if (!await file.exists()) return const None();
        return Some(await _load(path, file));
      });

  Future<MemoryFile> _load(MemoryPath path, File file) async => MemoryFile(
    path: path,
    content: await file.readAsString(),
    updatedAt: (await file.stat()).modified,
  );

  @override
  TaskEither<AppFailure, MemoryFile> create(MemoryPath path, String content) =>
      _write(() async {
        final file = _file(path);
        if (await file.exists()) {
          throw AppFailure.validation(
            message:
                '${path.value} already exists; use memory_patch to edit it',
          );
        }
        await file.parent.create(recursive: true);
        await file.writeAsString(_withTrailingNewline(content), flush: true);
        return _load(path, file);
      });

  @override
  TaskEither<AppFailure, MemoryFile> patch(MemoryPath path, String diff) =>
      _write(() async {
        final file = _file(path);
        if (!await file.exists()) {
          throw AppFailure.validation(
            message: '${path.value} does not exist; use memory_create',
          );
        }
        final updated = applyUnifiedDiff(
          await file.readAsString(),
          diff,
        ).getOrElse((failure) => throw failure);
        await file.writeAsString(updated, flush: true);
        return _load(path, file);
      });

  @override
  TaskEither<AppFailure, Unit> delete(MemoryPath path) => _write(() async {
    final file = _file(path);
    if (!await file.exists()) {
      throw AppFailure.validation(message: '${path.value} does not exist');
    }
    await file.delete();
    var dir = file.parent;
    while (p.isWithin(root.path, dir.path) && await dir.list().isEmpty) {
      await dir.delete();
      dir = dir.parent;
    }
    return unit;
  });

  @override
  TaskEither<AppFailure, List<MemorySearchHit>> search(
    String keywords, {
    int limit = 30,
  }) => _read(() async {
    final terms = keywords
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((t) => t.isNotEmpty)
        .toList();
    if (terms.isEmpty) return const <MemorySearchHit>[];
    final hits = <MemorySearchHit>[];
    for (final entry in await _entries()) {
      final lines = const LineSplitter().convert(
        await _file(entry.path).readAsString(),
      );
      for (final (index, line) in lines.indexed) {
        final lower = '${entry.path.value} $line'.toLowerCase();
        if (terms.every(lower.contains) && line.trim().isNotEmpty) {
          hits.add(
            MemorySearchHit(path: entry.path, line: index + 1, text: line),
          );
          if (hits.length >= limit) return hits;
        }
      }
    }
    return hits;
  });

  static String _withTrailingNewline(String content) =>
      content.isEmpty || content.endsWith('\n') ? content : '$content\n';
}
