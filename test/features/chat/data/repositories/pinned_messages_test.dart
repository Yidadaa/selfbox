import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:selfbox/core/database/app_store.dart';
import 'package:selfbox/features/chat/data/repositories/objectbox_message_repository.dart';
import 'package:selfbox/features/chat/domain/models/message.dart';

import '../../../../support/temp_storage.dart';

void main() {
  test(
    'ID state survives store reopen without emitting timeline updates',
    () async {
      final paths = createTempAppPaths();
      final store = await openAppStore(paths);
      final repo = ObjectBoxMessageRepository(store);
      final message =
          (await repo
                  .add(
                    const MessageDraft(
                      author: MessageAuthor.me,
                      text: 'persistent',
                    ),
                  )
                  .run())
              .getOrElse((failure) => fail('$failure'));
      final ready = Completer<void>();
      final events = <List<Message>>[];
      final subscription = repo.watchLatest(20).listen((messages) {
        events.add(messages);
        if (!ready.isCompleted) ready.complete();
      });
      await ready.future;
      await repo.setPinned(message.id, pinned: true).run();
      expect((await repo.watchPinned().first).single.id, message.id);
      expect(events.length, 1);
      await subscription.cancel();
      store.close();
      final reopened = await openAppStore(paths);
      addTearDown(reopened.close);
      expect(
        (await ObjectBoxMessageRepository(
          reopened,
        ).watchPinned().first).single.id,
        message.id,
      );
    },
  );

  test(
    'concurrent ID additions are atomic and closed store reports failure',
    () async {
      final store = await openAppStore(createTempAppPaths());
      final repo = ObjectBoxMessageRepository(store);
      final messages = await Future.wait(
        List.generate(
          8,
          (i) async =>
              (await repo
                      .add(MessageDraft(author: MessageAuthor.me, text: '$i'))
                      .run())
                  .getOrElse((failure) => fail('$failure')),
        ),
      );
      await Future.wait(
        messages.map((m) => repo.setPinned(m.id, pinned: true).run()),
      );
      expect((await repo.watchPinned().first).length, 8);
      await repo.clearAll().run();
      expect(await repo.watchPinned().first, isEmpty);
      store.close();
      expect((await repo.setPinned(1, pinned: true).run()).isLeft(), true);
      expect((await repo.clearPins().run()).isLeft(), true);
    },
  );
  test('pins persist, deduplicate and follow timeline ordering', () async {
    final store = await openTempStore();
    final repo = ObjectBoxMessageRepository(store, clock: () => DateTime(2026));
    Future<Message> add(String text) async =>
        (await repo
                .add(MessageDraft(author: MessageAuthor.me, text: text))
                .run())
            .getOrElse((failure) => fail('$failure'));
    final first = await add('first');
    final second = await add('second');
    await repo.setPinned(second.id, pinned: true).run();
    await repo.setPinned(first.id, pinned: true).run();
    await repo.setPinned(first.id, pinned: true).run();
    final reopened = ObjectBoxMessageRepository(store);
    expect((await reopened.watchPinned().first).map((m) => m.id), [
      second.id,
      first.id,
    ]);
    await repo.setPinned(first.id, pinned: false).run();
    expect((await repo.watchPinned().first).single.id, second.id);
    await repo.delete(second.id).run();
    expect(await repo.watchPinned().first, isEmpty);
    expect((await repo.latest(20).run()).toNullable()?.length, 1);
  });

  test('clear pins preserves messages and missing IDs are harmless', () async {
    final repo = ObjectBoxMessageRepository(await openTempStore());
    final message =
        (await repo
                .add(
                  const MessageDraft(
                    author: MessageAuthor.ai,
                    text: 'retained',
                  ),
                )
                .run())
            .getOrElse((failure) => fail('$failure'));
    await repo.setPinned(message.id, pinned: true).run();
    expect((await repo.setPinned(999, pinned: true).run()).isRight(), true);
    expect((await repo.clearPins().run()).isRight(), true);
    expect(await repo.watchPinned().first, isEmpty);
    expect((await repo.byId(message.id).run()).toNullable()?.isSome(), true);
  });
}
