import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:selfbox/features/chat/domain/models/message.dart';
import 'package:selfbox/features/chat/presentation/providers/chat_scroll_controller.dart';
import 'package:selfbox/features/chat/presentation/providers/composer_controller.dart';
import 'package:selfbox/features/chat/presentation/widgets/chat_composer_controls.dart';
import 'package:selfbox/features/chat/presentation/widgets/chat_timeline_message_row.dart';

import '../../../../support/app_widget_tester.dart';
import '../../../../support/fake_message_repository.dart';

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
    scroll.jumpTo(100);
    await tester.pumpAndSettle();
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
              _message(1),
              for (var id = 2; id <= 35; id++) _message(id, ai: true),
              _message(36),
            ],
          ),
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
          container.read(composerControllerProvider.notifier).toggleAiMode();
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
        ],
      ),
    );
    container.read(composerControllerProvider.notifier).toggleAiMode();
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
        ],
      ),
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
    composer.toggleAiMode();
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
    final container = await tester.pumpApp(messages: messages);
    container.read(composerControllerProvider.notifier).toggleAiMode();
    await tester.pumpAndSettle();
    await messages.delete(1).run();
    await tester.pumpAndSettle();
    expect(_row(1), findsNothing);
    await messages.clearAll().run();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
