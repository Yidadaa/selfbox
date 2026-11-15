import 'package:flutter_test/flutter_test.dart';
import 'package:selfbox/core/router/app_router.dart';
import 'package:selfbox/core/router/app_routes.dart';
import 'package:selfbox/core/theme/app_icons.dart';
import 'package:selfbox/features/chat/domain/models/message.dart';
import 'package:selfbox/features/chat/presentation/pages/chat_page.dart';
import 'package:selfbox/features/chat/presentation/providers/composer_controller.dart';
import 'package:selfbox/features/chat/presentation/widgets/message_bubble.dart';
import 'package:selfbox/gen/i18n/strings.g.dart';

import '../../../../support/app_widget_tester.dart';
import '../../../../support/fake_message_repository.dart';
import '../../../../support/icon_finder.dart';
import 'chat_page_test_support.dart';

List<Message> _messages() => [
  testMessage(1, 'older note', at: DateTime(2026, 11, 12, 9, 30, 5)),
  testMessage(2, 'newer note', at: DateTime(2026, 11, 12, 9, 30, 45)),
  testMessage(3, 'different minute', at: DateTime(2026, 11, 12, 9, 31, 7)),
];

Finder _bubble(int id) => find.byWidgetPredicate(
  (widget) => widget is MessageBubble && widget.message.id == id,
);

Finder _time(int id, String time) =>
    find.descendant(of: _bubble(id), matching: find.text(time));

Future<void> _doubleTap(WidgetTester tester, Offset position) async {
  await _tapAt(tester, position);
  await tester.pump(const Duration(milliseconds: 80));
  await _tapAt(tester, position);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}

Duration _eventTime(WidgetTester tester) =>
    Duration(microseconds: tester.binding.clock.now().microsecondsSinceEpoch);

Future<void> _tapAt(WidgetTester tester, Offset position) async {
  final gesture = await tester.createGesture();
  await gesture.down(position, timeStamp: _eventTime(tester));
  await tester.pump(const Duration(milliseconds: 16));
  await gesture.up(timeStamp: _eventTime(tester));
}

void main() {
  testWidgets('single taps, long presses and dragging do not reveal seconds', (
    tester,
  ) async {
    await tester.pumpApp(messages: FakeMessageRepository(seed: _messages()));
    const position = Offset(32, 300);
    final hold = await tester.createGesture();
    await hold.down(position, timeStamp: _eventTime(tester));
    await tester.pump(const Duration(milliseconds: 600));
    await hold.up(timeStamp: _eventTime(tester));
    await _tapAt(tester, position);
    await tester.pumpAndSettle();
    expect(_time(1, '09:30:05'), findsNothing);
    await tester.pump(const Duration(seconds: 1));
    final drag = await tester.createGesture();
    await drag.down(position, timeStamp: _eventTime(tester));
    await tester.pump(const Duration(milliseconds: 16));
    await drag.moveBy(const Offset(0, -40), timeStamp: _eventTime(tester));
    await drag.moveTo(position, timeStamp: _eventTime(tester));
    await drag.up(timeStamp: _eventTime(tester));
    await tester.pump(const Duration(milliseconds: 80));
    await _tapAt(tester, position);
    await tester.pumpAndSettle();
    expect(_time(1, '09:30:05'), findsNothing);
    expect(_time(2, '09:30'), findsOneWidget);
  });

  testWidgets(
    'only newest adjacent message keeps minute; deletion updates it',
    (tester) async {
      final repository = FakeMessageRepository(seed: _messages());
      await tester.pumpApp(messages: repository);
      expect(_time(1, '09:30'), findsNothing);
      expect(_time(2, '09:30'), findsOneWidget);
      expect(_time(3, '09:31'), findsOneWidget);
      await repository.delete(2).run();
      await tester.pumpAndSettle();
      expect(_time(1, '09:30'), findsOneWidget);
    },
  );

  for (final target in ['blank', 'message']) {
    testWidgets('double tap $target reveals seconds until leaving chat', (
      tester,
    ) async {
      final repository = FakeMessageRepository(
        seed: _messages(),
        clock: () => DateTime(2026, 11, 12, 9, 31, 20),
      );
      final container = await tester.pumpApp(messages: repository);
      final position = target == 'blank'
          ? const Offset(32, 300)
          : tester.getCenter(find.text('newer note'));
      await _doubleTap(tester, position);
      expect(_time(1, '09:30:05'), findsOneWidget);
      expect(_time(2, '09:30:45'), findsOneWidget);
      expect(_time(3, '09:31:07'), findsOneWidget);
      // No timeout, and another double tap does not toggle back.
      await tester.pump(const Duration(minutes: 3));
      await _doubleTap(tester, const Offset(32, 300));
      await repository
          .add(
            const MessageDraft(author: MessageAuthor.me, text: 'new arrival'),
          )
          .run();
      await tester.pumpAndSettle();
      expect(_time(4, '09:31:20'), findsOneWidget);
      expect(_time(3, '09:31:07'), findsOneWidget);

      container.read(composerControllerProvider.notifier).toggleAiMode();
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(_time(1, '09:30:05'), findsOneWidget);
      container.read(composerControllerProvider.notifier).toggleAiMode();
      await tester.pumpAndSettle();

      await tester.tap(find.text(t.tabs.memory));
      await tester.pumpAndSettle();
      await tester.tap(find.text(t.tabs.chat));
      await tester.pumpAndSettle();
      expect(find.byType(ChatPage), findsOneWidget);
      expect(_time(1, '09:30:05'), findsNothing);
      expect(_time(1, '09:30'), findsNothing);
      expect(_time(2, '09:30'), findsOneWidget);
      expect(_time(3, '09:31'), findsNothing);
      expect(_time(4, '09:31'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('opening a pushed page resets precision when returning', (
    tester,
  ) async {
    final container = await tester.pumpApp(
      messages: FakeMessageRepository(seed: _messages()),
    );
    await _doubleTap(tester, const Offset(32, 300));
    expect(_time(1, '09:30:05'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel(t.chat.searchMessages));
    await tester.pumpAndSettle();
    container.read(appRouterProvider).pop();
    await tester.pumpAndSettle();
    expect(_time(1, '09:30:05'), findsNothing);
    expect(_time(2, '09:30'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('AI badge survives hidden time; expanded messages show seconds', (
    tester,
  ) async {
    final container = await tester.pumpApp(
      messages: FakeMessageRepository(
        seed: [
          testMessage(
            1,
            'question',
            at: DateTime(2026, 11, 12, 9, 30, 5),
          ).copyWith(askedAi: true),
          testMessage(
            2,
            'answer',
            at: DateTime(2026, 11, 12, 9, 30, 45),
            author: MessageAuthor.ai,
          ),
        ],
      ),
    );
    await _doubleTap(tester, const Offset(32, 300));
    container.read(composerControllerProvider.notifier).toggleAiMode();
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(_time(1, '09:30:05'), findsOneWidget);
    expect(_time(2, '09:30:45'), findsOneWidget);

    container.read(appRouterProvider).go(const MemoryRoute().location);
    await tester.pumpAndSettle();
    container.read(appRouterProvider).go(const ChatRoute().location);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(_time(1, '09:30'), findsNothing);
    expect(_time(2, '09:30'), findsOneWidget);
    expect(
      find.descendant(of: _bubble(1), matching: findAppIcon(AppIcons.ai)),
      findsOneWidget,
    );
    await _doubleTap(
      tester,
      tester.getCenter(find.text('answer', findRichText: true)),
    );
    expect(_time(1, '09:30:05'), findsOneWidget);
    expect(_time(2, '09:30:45'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('welcome messages keep their footers hidden after double tap', (
    tester,
  ) async {
    await tester.pumpApp();
    await _doubleTap(tester, const Offset(32, 300));
    expect(find.byType(MessageBubble), findsNWidgets(3));
    expect(
      tester
          .widgetList<MessageBubble>(find.byType(MessageBubble))
          .every((bubble) => !bubble.showFooter),
      isTrue,
    );
    expect(find.text('10:00:00'), findsNothing);
  });
}
