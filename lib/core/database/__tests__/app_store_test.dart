import 'package:flutter_test/flutter_test.dart';
import 'package:selfbox/core/database/app_store.dart';
import 'package:selfbox/core/testing/temp_storage.dart';
import 'package:selfbox/features/chat/data/datasources/message_entity.dart';

void main() {
  group('openAppStore', () {
    test('creates the database under the sandboxed directory', () async {
      final paths = createTempAppPaths();
      final store = await openTempStore(paths);

      expect(paths.database.existsSync(), isTrue);
      expect(store.box<MessageEntity>().isEmpty(), isTrue);
    });

    test('reopens an existing database with its data', () async {
      final paths = createTempAppPaths();
      final first = await openAppStore(paths);
      first.box<MessageEntity>().put(
        MessageEntity(
          createdAt: DateTime(2026),
          author: 0,
          text: 'kept',
          images: const [],
          askedAi: false,
        ),
      );
      first.close();

      final second = await openTempStore(paths);
      expect(second.box<MessageEntity>().getAll().single.text, 'kept');
    });
  });
}
