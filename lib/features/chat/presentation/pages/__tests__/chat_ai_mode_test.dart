import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:selfbox/core/testing/app_widget_tester.dart';
import 'package:selfbox/core/testing/fake_message_repository.dart';
import 'package:selfbox/core/testing/icon_finder.dart';
import 'package:selfbox/core/theme/app_icons.dart';
import 'package:selfbox/core/theme/app_spacing.dart';
import 'package:selfbox/features/chat/domain/models/message.dart';
import 'package:selfbox/features/chat/presentation/providers/composer_controller.dart';
import 'package:selfbox/features/chat/presentation/widgets/message_bubble.dart';
import 'package:selfbox/features/chat/presentation/widgets/outgoing_message_entrance.dart';
import 'package:selfbox/features/settings/domain/models/app_preferences.dart';
import 'package:selfbox/gen/i18n/strings.g.dart';

import 'chat_page_test_support.dart';

void main() {
  testWidgets('incoming AI messages do not replay the send entrance', (
    tester,
  ) async {
    final messages = FakeMessageRepository(seed: [testMessage(1, 'older')]);
    final container = await tester.pumpApp(messages: messages);
    container.read(composerControllerProvider.notifier).toggleAiMode();
    await tester.pump(const Duration(milliseconds: 600));
    await messages
        .add(const MessageDraft(author: MessageAuthor.ai, text: 'reply'))
        .run();
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.byType(OutgoingMessageEntrance), findsNothing);
    expect(find.text('reply', findRichText: true), findsOneWidget);
  });

  testWidgets('folds AI exchanges and opens them from the summary', (
    tester,
  ) async {
    final day = kTestNow;
    final messages = FakeMessageRepository(
      seed: [
        testMessage(1, 'ordinary before', at: day),
        testMessage(2, 'first question', at: day).copyWith(askedAi: true),
        testMessage(3, 'first answer', author: MessageAuthor.ai, at: day),
        testMessage(4, 'second question', at: day).copyWith(askedAi: true),
        testMessage(5, 'second answer', author: MessageAuthor.ai, at: day),
        testMessage(6, 'ordinary after', at: day),
      ],
    );
    final container = await tester.pumpApp(messages: messages);
    final summary = t.chat.hiddenAiGroups(count: 2);

    expect(find.text(summary), findsOneWidget);
    final collapsed = find.byKey(const ValueKey('hidden-ai-group'));
    expect(
      find.descendant(of: collapsed, matching: findAppIcon(AppIcons.aiHidden)),
      findsOneWidget,
    );
    expect(
      find.descendant(of: collapsed, matching: findAppIcon(AppIcons.next)),
      findsOneWidget,
    );
    expect(
      find.ancestor(of: find.text(summary), matching: find.byType(ShaderMask)),
      findsOneWidget,
    );
    expect(summary, isNot(contains('(')));
    expect(find.text('ordinary before'), findsOneWidget);
    expect(find.text('ordinary after'), findsOneWidget);
    expect(find.text('first question'), findsNothing);
    expect(find.text('first answer', findRichText: true), findsNothing);

    final summaryX = tester.getTopLeft(collapsed).dx;
    await tester.tap(find.byKey(const ValueKey('hidden-ai-group')));
    await tester.pump();
    expect(container.read(composerControllerProvider).aiMode, isTrue);
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text(summary), findsOneWidget);
    expect(find.text('first answer', findRichText: true), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('first answer', findRichText: true)).dx,
      closeTo(summaryX, AppSpacing.md),
    );
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text(summary), findsNothing);
    expect(find.text('first question'), findsOneWidget);
    expect(find.text('second question'), findsOneWidget);

    container.read(composerControllerProvider.notifier).toggleAiMode();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text(summary), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text(summary), findsOneWidget);
    expect(find.text('first question'), findsNothing);
    expect(find.text('first answer', findRichText: true), findsNothing);
    expect(find.byType(OutgoingMessageEntrance), findsNothing);
  });

  testWidgets('folded AI messages switch immediately with animations off', (
    tester,
  ) async {
    final container = await tester.pumpApp(
      initialPreferences: const AppPreferences(animationsEnabled: false),
      messages: FakeMessageRepository(
        seed: [testMessage(1, 'question').copyWith(askedAi: true)],
      ),
    );
    expect(find.text(t.chat.hiddenAiGroups(count: 1)), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('hidden-ai-group')));
    await tester.pump();
    expect(container.read(composerControllerProvider).aiMode, isTrue);
    expect(find.text('question'), findsOneWidget);
    expect(find.text(t.chat.hiddenAiGroups(count: 1)), findsNothing);
  });

  testWidgets('puts my notes on the right and AI replies on the left', (
    tester,
  ) async {
    final container = await tester.pumpApp(
      messages: FakeMessageRepository(
        seed: [
          testMessage(1, 'mine'),
          testMessage(2, 'from ai', author: MessageAuthor.ai),
        ],
      ),
    );

    container.read(composerControllerProvider.notifier).toggleAiMode();
    await tester.pump(const Duration(milliseconds: 600));

    final width = tester.view.physicalSize.width / tester.view.devicePixelRatio;
    expect(tester.getCenter(find.text('mine')).dx, greaterThan(width / 2));
    expect(
      tester.getCenter(find.text('from ai', findRichText: true)).dx,
      lessThan(width / 2),
    );
  });

  testWidgets('marks notes that were sent to the AI', (tester) async {
    final container = await tester.pumpApp(
      messages: FakeMessageRepository(
        seed: [
          testMessage(1, 'plain'),
          testMessage(2, 'asked').copyWith(askedAi: true),
        ],
      ),
    );
    container.read(composerControllerProvider.notifier).toggleAiMode();
    await tester.pump(const Duration(milliseconds: 600));
    // Filled sparkle = AI question mark (the composer toggle is outlined).
    expect(
      find.descendant(
        of: find.byType(MessageBubble),
        matching: findAppIcon(AppIcons.ai),
      ),
      findsOneWidget,
    );
  });
}
