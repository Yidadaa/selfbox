import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:selfbox/features/chat/domain/models/agent_activity.dart';
import 'package:selfbox/features/chat/domain/models/message.dart';
import 'package:selfbox/features/chat/presentation/providers/assistant_controller.dart';
import 'package:selfbox/features/chat/presentation/providers/chat_feed.dart';
import 'package:selfbox/features/chat/presentation/providers/chat_scroll_controller.dart';
import 'package:selfbox/features/chat/presentation/providers/composer_controller.dart';
import 'package:selfbox/features/chat/presentation/widgets/assistant_status_bubble.dart';
import 'package:selfbox/features/chat/presentation/widgets/chat_timeline_message_row.dart';
import 'package:selfbox/features/chat/presentation/widgets/chat_timeline_view.dart';

import '../../../../support/app_widget_tester.dart';
import '../../../../support/fake_message_repository.dart';

class _Assistant extends AssistantController {
  @override
  AssistantState build() => const AssistantState.idle();

  void think(String text) =>
      state = AssistantState.working(AgentActivity.thinking(text: text));
}

class _PagedMessages extends FakeMessageRepository {
  _PagedMessages()
    : super(seed: [for (var id = 1; id <= 120; id++) _message(id)]);
  final ready = Completer<void>();
  final requests = <int>[];

  @override
  Stream<List<Message>> watchLatest(int limit) async* {
    requests.add(limit);
    if (limit > ChatWindow.pageSize) await ready.future;
    yield* super.watchLatest(limit);
  }
}

Message _message(int id, {bool ai = false}) => Message(
  id: id,
  createdAt: kTestNow,
  author: ai ? MessageAuthor.ai : MessageAuthor.me,
  text: 'Message $id',
);

Finder get _list => find.descendant(
  of: find.byType(ChatTimelineView),
  matching: find.byType(ListView),
);

void main() {
  testWidgets('repeated scroll events request only one pending history page', (
    tester,
  ) async {
    final messages = _PagedMessages();
    addTearDown(() {
      if (!messages.ready.isCompleted) messages.ready.complete();
    });
    final container = await tester.pumpApp(messages: messages);
    final scroll = container.read(chatScrollControllerProvider);
    scroll.jumpTo(scroll.position.maxScrollExtent);
    await tester.pump();
    for (var event = 1; event <= 3; event++) {
      scroll.jumpTo(scroll.position.maxScrollExtent - event);
      await tester.pump();
    }
    expect(messages.requests, [50, 100]);
    messages.ready.complete();
    await tester.pumpAndSettle();
    expect(container.read(chatMessagesProvider).value?.length, 100);
    expect(tester.takeException(), isNull);
  });
  testWidgets('thinking deltas update only the status subtree', (tester) async {
    final assistant = _Assistant();
    final container = await tester.pumpApp(
      messages: FakeMessageRepository(seed: [_message(1)]),
      overrides: [assistantControllerProvider.overrideWith(() => assistant)],
    );
    container.read(composerControllerProvider.notifier).toggleAiMode();
    container.read(assistantControllerProvider);
    assistant.think('First');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    final list = tester.widget<ListView>(_list);
    final row = tester.widget<ChatTimelineMessageRow>(
      find.byType(ChatTimelineMessageRow),
    );
    assistant.think('First and second');
    await tester.pump();
    expect(tester.widget<ListView>(_list), same(list));
    expect(
      tester.widget<ChatTimelineMessageRow>(
        find.byType(ChatTimelineMessageRow),
      ),
      same(row),
    );
    expect(
      tester
          .widget<AssistantStatusBubble>(find.byType(AssistantStatusBubble))
          .state,
      const AssistantState.working(
        AgentActivity.thinking(text: 'First and second'),
      ),
    );
  });

  testWidgets('expanded AI discussions mount only visible messages', (
    tester,
  ) async {
    final container = await tester.pumpApp(
      messages: FakeMessageRepository(
        seed: [for (var id = 1; id <= 200; id++) _message(id, ai: true)],
      ),
    );
    for (var page = 0; page < 3; page++) {
      container.read(chatWindowProvider.notifier).loadMore();
    }
    container.read(composerControllerProvider.notifier).toggleAiMode();
    await tester.pumpAndSettle();
    expect(find.byType(ChatTimelineMessageRow).evaluate().length, lessThan(25));
    expect(find.text('Message 200', findRichText: true), findsOneWidget);
    await tester.drag(_list, const Offset(0, 700));
    await tester.pumpAndSettle();
    expect(find.byType(ChatTimelineMessageRow).evaluate().length, lessThan(25));
    expect(tester.takeException(), isNull);
  });

  testWidgets('keyboard frames preserve the timeline list configuration', (
    tester,
  ) async {
    await tester.pumpApp(messages: FakeMessageRepository(seed: [_message(1)]));
    await tester.tap(find.byType(EditableText));
    await tester.pumpAndSettle();
    final list = tester.widget<ListView>(_list);
    final before = tester.getRect(find.byType(ChatTimelineMessageRow));
    for (final inset in [120.0, 300.0, 600.0, 900.0]) {
      tester.view.viewInsets = FakeViewPadding(bottom: inset);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));
      expect(tester.widget<ListView>(_list), same(list));
    }
    await tester.pumpAndSettle();
    expect(
      tester.getRect(find.byType(ChatTimelineMessageRow)).bottom,
      lessThan(before.bottom),
    );
    expect(tester.takeException(), isNull);
  });
}
