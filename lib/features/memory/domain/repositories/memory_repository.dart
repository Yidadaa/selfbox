import 'package:fpdart/fpdart.dart';

import '../../../../core/error/app_failure.dart';
import '../models/memory.dart';

/// The agent's markdown memory tree. Every write goes through here, so
/// [watchEntries] stays current without file-system watchers.
abstract interface class MemoryRepository {
  /// All files, sorted by path, re-emitted after every write.
  Stream<List<MemoryEntry>> watchEntries();

  TaskEither<AppFailure, List<MemoryEntry>> list();

  TaskEither<AppFailure, Option<MemoryFile>> read(MemoryPath path);

  /// Fails if the file already exists: updates must go through [patch].
  TaskEither<AppFailure, MemoryFile> create(MemoryPath path, String content);

  /// Applies a unified diff to the current content.
  TaskEither<AppFailure, MemoryFile> patch(MemoryPath path, String diff);

  /// Removes the file and any folders left empty.
  TaskEither<AppFailure, Unit> delete(MemoryPath path);

  /// Case-insensitive line matches for every keyword.
  TaskEither<AppFailure, List<MemorySearchHit>> search(
    String keywords, {
    int limit = 30,
  });
}
