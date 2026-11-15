import 'package:flutter_test/flutter_test.dart';
import 'package:selfbox/core/testing/temp_storage.dart';
import 'package:selfbox/features/chat/data/repositories/objectbox_message_repository.dart';
import 'package:selfbox/features/chat/domain/models/message.dart';

import 'objectbox_message_repository_test.dart' show pumpEventQueueUntil;

void main() {
  test(
    'live windows reuse retained messages across inserts and paging',
    () async {
      final repo = ObjectBoxMessageRepository(
        await openTempStore(),
        clock: () => DateTime(2026),
      );
      for (var index = 0; index < 5; index++) {
        await repo
            .add(MessageDraft(author: MessageAuthor.me, text: '$index'))
            .run();
      }
      final initial = await repo.watchLatest(3).first;
      final expanded = await repo.watchLatest(5).first;
      expect(expanded.take(3), orderedEquals(initial));
      expect(expanded.first, same(initial.first));
      final emissions = <List<Message>>[];
      final subscription = repo.watchLatest(5).listen(emissions.add);
      addTearDown(subscription.cancel);
      await pumpEventQueueUntil(() => emissions.isNotEmpty);
      await repo
          .add(const MessageDraft(author: MessageAuthor.me, text: 'new'))
          .run();
      await pumpEventQueueUntil(() => emissions.last.first.text == 'new');
      expect(emissions.last[1], same(initial.first));
      expect(emissions.last.length, 5);
      expect(() => emissions.last.clear(), throwsUnsupportedError);
      await repo.delete(initial.first.id).run();
      await pumpEventQueueUntil(
        () => emissions.last.every((message) => message.id != initial.first.id),
      );
      expect(emissions.last.map((message) => message.text), [
        'new',
        '3',
        '2',
        '1',
        '0',
      ]);
      await repo.clearAll().run();
      await pumpEventQueueUntil(() => emissions.last.isEmpty);
      await repo
          .add(const MessageDraft(author: MessageAuthor.me, text: 'reset'))
          .run();
      await pumpEventQueueUntil(() => emissions.last.isNotEmpty);
      expect(emissions.last.single.text, 'reset');
    },
  );
}
