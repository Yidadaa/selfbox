import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:selfbox/features/chat/domain/models/message.dart';
import 'package:selfbox/features/chat/presentation/providers/chat_feed.dart';
import 'package:selfbox/main.dart';
import 'package:talker_flutter/talker_flutter.dart';
import 'package:talker_riverpod_logger/talker_riverpod_logger.dart';

import 'support/app_widget_tester.dart';
import 'support/fake_message_repository.dart';

class _ExpensiveState {
  var serializations = 0;

  @override
  String toString() {
    serializations++;
    return 'private long state';
  }
}

void main() {
  test('provider events retain identity without serializing state', () {
    final state = _ExpensiveState();
    final provider = Provider((ref) => state, name: 'expensiveState');
    final talker = Talker(settings: TalkerSettings(useConsoleLogs: false));
    final container = ProviderContainer(
      observers: [appRiverpodObserver(talker)],
    );
    addTearDown(container.dispose);
    container.read(provider);
    final logs = talker.history
        .map((entry) => entry.generateTextMessage())
        .join();
    expect(logs, contains('expensiveState'));
    expect(logs, isNot(contains('private long state')));
    expect(state.serializations, 0);
  });

  test('history paging logs remain bounded for long message batches', () async {
    final talker = Talker(settings: TalkerSettings(useConsoleLogs: false));
    final messages = FakeMessageRepository(
      seed: [
        for (var index = 1; index <= 100; index++)
          Message(
            id: index,
            createdAt: kTestNow,
            author: MessageAuthor.ai,
            text: List.filled(1000, 'private-long-message').join(),
          ),
      ],
    );
    final container = ProviderContainer(
      overrides: testAppOverrides(messages: messages),
      observers: [appRiverpodObserver(talker)],
    );
    addTearDown(container.dispose);
    container.listen(chatFeedProvider, (_, _) {});
    await container.read(chatMessagesProvider.future);
    container.read(chatWindowProvider.notifier).loadMore();
    await container.pump();
    await container.read(chatMessagesProvider.future);
    await container.pump();
    expect(container.read(chatMessagesProvider).requireValue.length, 100);
    final entries = talker.history
        .where(
          (entry) =>
              entry.message?.contains('chatMessagesProvider') == true ||
              entry.message?.contains('chatFeedProvider') == true,
        )
        .toList();
    expect(entries, isNotEmpty);
    for (final entry in entries) {
      final text = entry.generateTextMessage();
      expect(text, isNot(contains('private-long-message')));
      expect(text.length, lessThan(1000));
    }
  });

  test('provider failures retain error details and stack', () {
    final talker = Talker(settings: TalkerSettings(useConsoleLogs: false));
    final provider = Provider<int>(
      (ref) => throw StateError('repository offline'),
      name: 'failedRepository',
    );
    final container = ProviderContainer(
      observers: [appRiverpodObserver(talker)],
    );
    addTearDown(container.dispose);
    expect(() => container.read(provider), throwsA(anything));
    final failures = talker.history.whereType<RiverpodFailLog>().toList();
    expect(failures, hasLength(1));
    final text = failures.single.generateTextMessage();
    expect(text, contains('repository offline'));
    expect(text, contains('STACK TRACE'));
    expect(text, contains('main_test.dart'));
  });
}
