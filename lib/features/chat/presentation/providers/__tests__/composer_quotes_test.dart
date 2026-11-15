import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:selfbox/core/error/app_failure.dart';
import 'package:selfbox/core/testing/app_widget_tester.dart';
import 'package:selfbox/core/testing/fake_message_repository.dart';
import 'package:selfbox/features/chat/domain/models/message.dart';
import 'package:selfbox/features/chat/presentation/providers/composer_controller.dart';

void main() {
  final first = Message(
    id: 1,
    createdAt: kTestNow,
    author: MessageAuthor.me,
    text: 'one',
  );
  final second = first.copyWith(id: 2, author: MessageAuthor.ai, text: 'two');

  test(
    'quotes deduplicate, remove independently and survive failed send',
    () async {
      final messages = FakeMessageRepository(seed: [first, second]);
      final asked = <Message>[];
      final container = ProviderContainer(
        overrides: [
          ...testAppOverrides(messages: messages),
          onAskAiProvider.overrideWithValue(asked.add),
        ],
      );
      addTearDown(container.dispose);
      final composer = container.read(composerControllerProvider.notifier);
      composer
        ..quote(first)
        ..quote(second)
        ..quote(first);
      expect(container.read(composerControllerProvider).quotedMessageIds, [
        1,
        2,
      ]);
      expect(container.read(composerControllerProvider).canSend, false);
      composer.removeQuote(1);
      expect(container.read(composerControllerProvider).quotedMessageIds, [2]);
      composer
        ..quote(first)
        ..setText('compare')
        ..toggleAiMode();
      messages.failNextAdd = const Some(AppFailure.database(message: 'full'));
      await composer.send();
      expect(container.read(composerControllerProvider).quotedMessageIds, [
        2,
        1,
      ]);
      expect(asked, isEmpty);
      await composer.send();
      expect(asked.single.quotedMessageIds, [2, 1]);
      expect(
        container.read(composerControllerProvider).quotedMessageIds,
        isEmpty,
      );
      composer
        ..quote(first)
        ..resetDraft();
      expect(
        container.read(composerControllerProvider).quotedMessageIds,
        isEmpty,
      );
    },
  );
}
