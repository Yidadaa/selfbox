import 'package:fpdart/fpdart.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/memory_data_providers.dart';
import '../../domain/models/memory.dart';

part '../../../../gen/features/memory/presentation/providers/memory_providers.freezed.dart';
part '../../../../gen/features/memory/presentation/providers/memory_providers.g.dart';

@freezed
abstract class MemoryFolder with _$MemoryFolder {
  const factory MemoryFolder({
    /// Top-level folder name; empty for files at the root.
    required String name,
    required List<MemoryEntry> entries,
  }) = _MemoryFolder;
}

/// Groups entries by top-level folder; root files come first, then folders
/// alphabetically, each sorted newest-first.
List<MemoryFolder> groupMemoryEntries(List<MemoryEntry> entries) {
  final byFolder = <String, List<MemoryEntry>>{};
  for (final entry in entries) {
    byFolder.putIfAbsent(entry.path.folder, () => []).add(entry);
  }
  final folders = byFolder.entries.toList()
    ..sort((a, b) => a.key.compareTo(b.key));
  return List.unmodifiable([
    for (final MapEntry(key: name, value: files) in folders)
      MemoryFolder(
        name: name,
        entries: List.unmodifiable(
          files..sort((a, b) => b.updatedAt.compareTo(a.updatedAt)),
        ),
      ),
  ]);
}

@riverpod
Stream<List<MemoryFolder>> memoryFolders(Ref ref) =>
    ref.watch(memoryRepositoryProvider).watchEntries().map(groupMemoryEntries);

@riverpod
Future<Option<MemoryFile>> memoryFile(Ref ref, String path) async {
  // Re-read whenever the tree changes, e.g. the agent patches this file
  // while it is open.
  ref.watch(memoryFoldersProvider);
  return MemoryPath.parse(path).match(
    (_) async => const None(),
    (valid) async =>
        (await ref.watch(memoryRepositoryProvider).read(valid).run()).getOrElse(
          (_) => const None(),
        ),
  );
}
