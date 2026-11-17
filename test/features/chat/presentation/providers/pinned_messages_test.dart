import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:selfbox/core/error/app_failure.dart';
import 'package:selfbox/features/chat/data/chat_data_providers.dart';
import 'package:selfbox/features/chat/domain/models/message.dart';
import 'package:selfbox/features/chat/presentation/providers/message_actions.dart';
import 'package:selfbox/features/chat/presentation/providers/pinned_messages.dart';

import '../../../../support/fake_message_repository.dart';

void main() {
  test(
    'pins expose loading, empty, data and failure independently of timeline',
    () async {
      final repo = _ControlledPins();
      addTearDown(repo.changes.close);
      final container = ProviderContainer(
        overrides: [messageRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);
      final states = <AsyncValue<List<Message>>>[];
      container.listen(
        pinnedMessagesProvider,
        (_, next) => states.add(next),
        fireImmediately: true,
      );
      expect(states.last.isLoading, true);
      repo.changes.add(const []);
      expect(await container.read(pinnedMessagesProvider.future), isEmpty);
      repo.changes.add([
        Message(
          id: 1,
          createdAt: DateTime(2026),
          author: MessageAuthor.me,
          text: 'pin',
        ),
      ]);
      await Future<void>.delayed(Duration.zero);
      expect(container.read(pinnedMessagesProvider).value?.single.id, 1);
      repo.changes.addError(const AppFailure.database(message: 'offline'));
      await Future<void>.delayed(Duration.zero);
      expect(container.read(pinnedMessagesProvider).hasError, true);
      repo.changes.add(const []);
      await Future<void>.delayed(Duration.zero);
      expect(container.read(pinnedMessagesProvider).requireValue, isEmpty);
    },
  );

  test(
    'failed mutations remain explicit failures and preserve existing pins',
    () async {
      final repo = _ControlledPins();
      addTearDown(repo.changes.close);
      final container = ProviderContainer(
        overrides: [messageRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);
      final actions = container.read(messageActionsProvider.notifier);
      expect((await actions.pin(1, pinned: true)).isLeft(), true);
      expect((await actions.clearPins()).isLeft(), true);
    },
  );
}

class _ControlledPins extends FakeMessageRepository {
  final changes = StreamController<List<Message>>.broadcast();
  @override
  Stream<List<Message>> watchPinned() => changes.stream;
  @override
  TaskEither<AppFailure, Unit> setPinned(int id, {required bool pinned}) =>
      TaskEither.left(const AppFailure.database(message: 'write failed'));
  @override
  TaskEither<AppFailure, Unit> clearPins() =>
      TaskEither.left(const AppFailure.database(message: 'write failed'));
}
