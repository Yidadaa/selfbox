import 'package:flutter_test/flutter_test.dart';
import 'package:selfbox/features/memory/domain/models/memory.dart';
import 'package:selfbox/features/memory/presentation/providers/memory_providers.dart';

MemoryEntry _e(String path, int day) => MemoryEntry(
  path: MemoryPath.parse(path).getOrElse((f) => fail('$f')),
  updatedAt: DateTime(2026, 11, day),
  sizeBytes: 1,
  title: path,
);

void main() {
  group('groupMemoryEntries', () {
    test('is empty for no entries', () {
      expect(groupMemoryEntries(const []), isEmpty);
    });

    test('groups by top-level folder, root first, folders alphabetical', () {
      final folders = groupMemoryEntries([
        _e('user/profile.md', 1),
        _e('inbox.md', 1),
        _e('topic/hiking.md', 1),
        _e('topic/sub/deep.md', 1),
      ]);
      expect(folders.map((f) => f.name), ['', 'topic', 'user']);
      expect(folders[1].entries.map((e) => e.path.value), hasLength(2));
    });

    test('sorts files in a folder newest-first', () {
      final folders = groupMemoryEntries([
        _e('user/a.md', 1),
        _e('user/b.md', 3),
        _e('user/c.md', 2),
      ]);
      expect(folders.single.entries.map((e) => e.path.value), [
        'user/b.md',
        'user/c.md',
        'user/a.md',
      ]);
    });
  });
}
