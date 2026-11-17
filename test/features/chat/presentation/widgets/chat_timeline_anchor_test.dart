import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:selfbox/features/chat/domain/models/message.dart';
import 'package:selfbox/features/chat/presentation/providers/chat_scroll_controller.dart';
import 'package:selfbox/features/chat/presentation/providers/composer_controller.dart';
import 'package:selfbox/features/chat/presentation/widgets/chat_composer_controls.dart';
import 'package:selfbox/features/chat/presentation/widgets/chat_timeline_message_row.dart';

import '../../../../support/app_widget_tester.dart';
import '../../../../support/fake_message_repository.dart';
import 'chat_timeline_anchor_test_support.dart';

Message _message(int id, {bool ai = false}) => Message(
  id: id,
  createdAt: kTestNow.add(Duration(seconds: id)),
  author: ai ? MessageAuthor.ai : MessageAuthor.me,
  text: ai ? 'Discussion $id\n${'Long reply. ' * 25}' : 'Anchor $id',
);

Finder _row(int id) => find.byWidgetPredicate(
  (widget) => widget is ChatTimelineMessageRow && widget.message.id == id,
);

void main() {
  for (final historyLength in [1, 20]) {
    testWidgets('AI toggle stays at bottom with $historyLength user rows', (
      tester,
    ) async {
      final container = await tester.pumpApp(
        messages: FakeMessageRepository(
          seed: [
            for (var id = 1; id <= historyLength; id++) _message(id),
            for (var id = historyLength + 1; id <= historyLength + 30; id++)
              _message(id, ai: true),
          ],
        ),
      );
      final scroll = container.read(chatScrollControllerProvider);
      expect(scroll.position.extentBefore, 0);
      await tester.tap(find.byType(ChatAiToggle));
      await tester.pump();
      expect(scroll.position.extentBefore, closeTo(0, 1));
      expect(_row(historyLength + 30), findsOneWidget);
      await tester.pumpAndSettle();
      expect(scroll.position.extentBefore, closeTo(0, 1));
      expect(_row(historyLength + 30), findsOneWidget);
      expect(find.byKey(const ValueKey('chat-scroll-to-bottom')), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
  for (final previouslyExpanded in [false, true]) {
    testWidgets(
      'toggle anchors the top visible user after scrolling, previous card=$previouslyExpanded',
      (tester) async {
        final container = await tester.pumpApp(
          messages: FakeMessageRepository(
            seed: [
              for (var id = 1; id <= 40; id++)
                _message(
                  id,
                  ai:
                      (id >= 9 && id <= 12) ||
                      (id >= 19 && id <= 22) ||
                      (id >= 31 && id <= 34),
                ),
            ],
          ),
        );
        if (previouslyExpanded) {
          await tester.tap(find.byKey(const ValueKey('hidden-ai-group')).first);
          await tester.pumpAndSettle();
          await tester.tap(find.byType(ChatAiToggle));
          await tester.pumpAndSettle();
        }
        final scroll = container.read(chatScrollControllerProvider);
        await tester.scrollUntilVisible(
          _row(17),
          150,
          scrollable: find.descendant(
            of: find.byType(CustomScrollView),
            matching: find.byType(Scrollable),
          ),
        );
        await tester.pumpAndSettle();
        scroll.jumpTo(scroll.offset + 32 - tester.getTopLeft(_row(17)).dy);
        await tester.pumpAndSettle();
        final visible =
            find
                .byType(ChatTimelineMessageRow)
                .evaluate()
                .where(
                  (element) =>
                      (element.widget as ChatTimelineMessageRow)
                          .message
                          .author ==
                      MessageAuthor.me,
                )
                .map(
                  (element) => (
                    id: (element.widget as ChatTimelineMessageRow).message.id,
                    top: tester.getTopLeft(find.byWidget(element.widget)).dy,
                  ),
                )
                .where((row) => row.top >= 0 && row.top < kPhoneViewport.height)
                .toList()
              ..sort((first, second) => first.top.compareTo(second.top));
        expect(visible.first.id, 17);
        final before = visible.first.top;
        for (var toggle = 0; toggle < 2; toggle++) {
          await tester.tap(find.byType(ChatAiToggle));
          await tester.pump();
          expect(_row(17), findsOneWidget);
          expect(tester.getTopLeft(_row(17)).dy, closeTo(before, 1));
          await tester.pumpAndSettle();
          expect(tester.getTopLeft(_row(17)).dy, closeTo(before, 1));
        }
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('expanding while scrolled preserves the visible user position', (
    tester,
  ) async {
    final container = await tester.pumpApp(
      messages: FakeMessageRepository(
        seed: [
          for (var id = 1; id <= 12; id++) _message(id),
          for (var id = 13; id <= 40; id++) _message(id, ai: true),
          _message(41),
        ],
      ),
    );
    final scroll = container.read(chatScrollControllerProvider);
    await hideLatest(tester, scroll, _row(41));
    final before = tester.getTopLeft(_row(12));
    container.read(composerControllerProvider.notifier).toggleAiMode();
    await tester.pump();
    expect(tester.getTopLeft(_row(12)).dy, closeTo(before.dy, 1));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(_row(12)).dy, closeTo(before.dy, 1));
    expect(tester.takeException(), isNull);
  });

  for (final fromCard in [true, false]) {
    testWidgets(
      'long discussion keeps user position from ${fromCard ? 'card' : 'toggle'}',
      (tester) async {
        final container = await tester.pumpApp(
          messages: FakeMessageRepository(
            seed: [
              _message(1).copyWith(text: 'Anchor 1\n${'History\n' * 12}'),
              ...olderHistory(),
              for (var id = 2; id <= 35; id++) _message(id, ai: true),
              _message(36),
            ],
          ),
        );
        await hideLatest(
          tester,
          container.read(chatScrollControllerProvider),
          _row(36),
        );
        final before = tester.getTopLeft(_row(1));
        if (fromCard) {
          await tester.tap(find.byKey(const ValueKey('hidden-ai-group')));
        } else {
          await tester.tap(find.byType(ChatAiToggle));
        }
        await tester.pump();
        expect(_row(1), findsOneWidget);
        expect(tester.getTopLeft(_row(1)).dy, closeTo(before.dy, 1));
        await tester.pumpAndSettle();
        expect(tester.getTopLeft(_row(1)).dy, closeTo(before.dy, 1));
        expect(
          find.byType(ChatTimelineMessageRow).evaluate().length,
          lessThan(15),
        );
        for (var toggle = 0; toggle < 4; toggle++) {
          if (fromCard && !container.read(composerControllerProvider).aiMode) {
            await tester.tap(find.byKey(const ValueKey('hidden-ai-group')));
          } else {
            container.read(composerControllerProvider.notifier).toggleAiMode();
          }
          await tester.pumpAndSettle();
          expect(tester.getTopLeft(_row(1)).dy, closeTo(before.dy, 1));
        }
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('expanded discussion can return to the newest message', (
    tester,
  ) async {
    final container = await tester.pumpApp(
      messages: FakeMessageRepository(
        seed: [
          _message(1),
          for (var id = 2; id <= 35; id++) _message(id, ai: true),
          _message(36),
          ...olderHistory(),
        ],
      ),
    );
    await hideLatest(
      tester,
      container.read(chatScrollControllerProvider),
      _row(36),
    );
    await tester.tap(find.byKey(const ValueKey('hidden-ai-group')));
    await tester.pumpAndSettle();
    final button = find.byKey(const ValueKey('chat-scroll-to-bottom'));
    expect(button, findsOneWidget);
    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(_row(36), findsOneWidget);
    expect(
      container.read(chatScrollControllerProvider).position.extentBefore,
      closeTo(0, 1),
    );
    expect(button, findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tapping an older group anchors its own preceding user', (
    tester,
  ) async {
    final container = await tester.pumpApp(
      messages: FakeMessageRepository(
        seed: [
          _message(1),
          for (var id = 2; id <= 15; id++) _message(id, ai: true),
          _message(16),
          for (var id = 17; id <= 30; id++) _message(id, ai: true),
          _message(31),
          ...olderHistory(),
        ],
      ),
    );
    await hideLatest(
      tester,
      container.read(chatScrollControllerProvider),
      _row(31),
    );
    final before = tester.getTopLeft(_row(1));
    await tester.tap(find.byKey(const ValueKey('hidden-ai-group')).last);
    await tester.pumpAndSettle();
    expect(container.read(composerControllerProvider).aiMode, isTrue);
    expect(tester.getTopLeft(_row(1)).dy, closeTo(before.dy, 1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('sending from an anchored discussion reaches the new message', (
    tester,
  ) async {
    final container = await tester.pumpApp(
      messages: FakeMessageRepository(
        seed: [
          _message(1),
          for (var id = 2; id <= 35; id++) _message(id, ai: true),
        ],
        clock: () => kTestNow.add(const Duration(hours: 1)),
      ),
      overrides: [onAskAiProvider.overrideWithValue((_) {})],
    );
    final composer = container.read(composerControllerProvider.notifier);
    await tester.tap(find.byKey(const ValueKey('hidden-ai-group')));
    await tester.pumpAndSettle();
    composer.setText('New question');
    await composer.send();
    await tester.pumpAndSettle();
    expect(find.text('New question'), findsOneWidget);
    expect(
      container.read(chatScrollControllerProvider).position.extentBefore,
      closeTo(0, 1),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('removing the anchor and clearing history remains safe', (
    tester,
  ) async {
    final messages = FakeMessageRepository(
      seed: [
        _message(1),
        for (var id = 2; id <= 20; id++) _message(id, ai: true),
      ],
    );
    await tester.pumpApp(messages: messages);
    await tester.tap(find.byKey(const ValueKey('hidden-ai-group')));
    await tester.pumpAndSettle();
    await messages.delete(1).run();
    await tester.pumpAndSettle();
    expect(_row(1), findsNothing);
    await messages.clearAll().run();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
