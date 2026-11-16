import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:selfbox/core/theme/app_spacing.dart';
import 'package:selfbox/core/widgets/app_action_popover.dart';
import 'package:selfbox/core/widgets/app_confirm_dialog.dart';
import 'package:selfbox/core/widgets/empty_state.dart';
import 'package:selfbox/features/chat/domain/models/message.dart';
import 'package:selfbox/features/chat/presentation/pages/chat_page.dart';
import 'package:selfbox/features/chat/presentation/providers/chat_feed.dart';
import 'package:selfbox/features/chat/presentation/providers/composer_controller.dart';
import 'package:selfbox/features/chat/presentation/widgets/chat_composer.dart';
import 'package:selfbox/features/chat/presentation/widgets/day_pill.dart';
import 'package:selfbox/features/chat/presentation/widgets/message_bubble.dart';
import 'package:selfbox/features/chat/presentation/widgets/message_image_stack.dart';
import 'package:selfbox/gen/i18n/strings.g.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../../support/app_widget_tester.dart';
import '../../../../support/fake_message_repository.dart';
import 'chat_page_test_support.dart';

void main() {
  group('ChatPage', () {
    testWidgets('loading timeline keeps the merged composer available', (
      tester,
    ) async {
      await tester.pumpApp(
        overrides: [
          chatMessagesProvider.overrideWith(
            (ref) => const Stream<List<Message>>.empty(),
          ),
        ],
        settle: false,
      );
      await tester.pump(const Duration(milliseconds: 500));
      expect(
        find.byWidgetPredicate((widget) => widget is Skeletonizer),
        findsOneWidget,
      );
      expect(find.byType(ChatComposer), findsOneWidget);
      expect(find.text(t.tabs.memory), findsOneWidget);
      expect(
        tester
            .getRect(
              find.descendant(
                of: find.byType(ChatPage),
                matching: find.byType(ListView),
              ),
            )
            .top,
        0,
      );
    });

    testWidgets('timeline retry recovers without clearing the draft', (
      tester,
    ) async {
      var attempts = 0;
      await tester.pumpApp(
        overrides: [
          chatMessagesProvider.overrideWith(
            (ref) => attempts++ == 0
                ? Stream<List<Message>>.error(StateError('unavailable'))
                : Stream.value([testMessage(1, 'recovered')]),
          ),
        ],
      );
      await tester.enterText(composerField(), 'keep this draft');
      await tester.pump();
      await tester.tap(find.text(t.common.retry));
      await tester.pumpAndSettle();
      expect(find.text('recovered'), findsOneWidget);
      expect(
        tester.widget<EditableText>(composerField()).controller.text,
        'keep this draft',
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('shows three ephemeral AI greetings with the composer', (
      tester,
    ) async {
      final messages = FakeMessageRepository();
      await tester.pumpApp(messages: messages);

      expect(find.byType(EmptyState), findsNothing);
      expect(find.byType(MessageBubble), findsNWidgets(3));
      for (final greeting in [
        t.chat.welcomeFirst,
        t.chat.welcomeSecond,
        t.chat.welcomeThird,
      ]) {
        expect(
          find.textContaining(greeting, findRichText: true),
          findsOneWidget,
        );
      }
      expect(messages.added, isEmpty);
      expect(find.byType(ChatComposer), findsOneWidget);
      expect(
        tester
            .getRect(
              find.descendant(
                of: find.byType(ChatPage),
                matching: find.byType(ListView),
              ),
            )
            .top,
        0,
      );
    });

    testWidgets('the timeline scrolls behind the profile header', (
      tester,
    ) async {
      await tester.pumpApp(
        messages: FakeMessageRepository(
          seed: [for (var id = 1; id <= 12; id++) testMessage(id, 'Note $id')],
        ),
      );

      final timeline = find.descendant(
        of: find.byType(ChatPage),
        matching: find.byType(CustomScrollView),
      );
      expect(timeline, findsOneWidget);
      expect(tester.getRect(timeline).top, 0);
      final list = tester.widget<CustomScrollView>(timeline);
      final safeTop = MediaQuery.paddingOf(tester.element(timeline)).top;
      expect(
        ((list.slivers.last as SliverPadding).padding as EdgeInsets).top,
        safeTop + AppSizes.chatHeaderHeight + AppSpacing.md,
      );
    });

    testWidgets('shows a bottom jump button while reading older messages', (
      tester,
    ) async {
      final container = await tester.pumpApp(
        messages: FakeMessageRepository(
          seed: [for (var id = 1; id <= 40; id++) testMessage(id, 'Note $id')],
        ),
      );
      container
          .read(composerControllerProvider.notifier)
          .quote(testMessage(40, 'Note 40'));
      await tester.pumpAndSettle();
      final quoteRect = tester.getRect(
        find.byKey(const ValueKey('composer-quotes')),
      );

      final timeline = find.descendant(
        of: find.byType(ChatPage),
        matching: find.byType(CustomScrollView),
      );
      await tester.drag(timeline, const Offset(0, 500));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('chat-scroll-to-bottom')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('composer-quotes')), findsNothing);
      final jumpRect = tester.getRect(
        find.byKey(const ValueKey('chat-scroll-to-bottom')),
      );
      expect(jumpRect.topLeft, quoteRect.topLeft);
      expect(jumpRect.height, quoteRect.height);

      await tester.tap(find.byKey(const ValueKey('chat-scroll-to-bottom')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('chat-scroll-to-bottom')), findsNothing);
      expect(find.byKey(const ValueKey('composer-quotes')), findsOneWidget);
    });

    testWidgets('groups messages under day pills', (tester) async {
      await tester.pumpApp(
        messages: FakeMessageRepository(
          seed: [
            testMessage(1, 'old', at: DateTime(2026, 11, 11, 9)),
            testMessage(2, 'new', at: DateTime(2026, 11, 12, 9)),
          ],
        ),
      );

      expect(find.byType(DayPill), findsNWidgets(2));
      expect(find.text(t.chat.today), findsOneWidget);
      expect(find.text(t.chat.yesterday), findsOneWidget);
      // Reversed list: the older day renders above the newer one.
      expect(
        tester.getTopLeft(find.text(t.chat.yesterday)).dy,
        lessThan(tester.getTopLeft(find.text(t.chat.today)).dy),
      );
    });

    testWidgets('long-press offers copy and delete; delete removes it', (
      tester,
    ) async {
      String? clipboard;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            clipboard =
                (call.arguments as Map<Object?, Object?>)['text'] as String;
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      final messages = FakeMessageRepository(
        seed: [testMessage(1, 'remove me')],
      );
      await tester.pumpApp(messages: messages);

      await tester.longPress(find.text('remove me'));
      await tester.pumpAndSettle();
      expect(find.byType(AppActionPopover), findsOneWidget);

      expect(find.text(t.common.copy), findsOneWidget);

      await tester.tap(find.text(t.common.copy));
      await tester.pumpAndSettle();
      expect(clipboard, 'remove me');
      expect(find.widgetWithText(GlassToast, t.common.copied), findsOneWidget);
      await tester.pump(const Duration(seconds: 4));
      await tester.longPress(find.text('remove me'));
      await tester.pumpAndSettle();

      await tester.tap(find.text(t.common.delete));
      await tester.pumpAndSettle();

      expect(find.byType(AppConfirmDialog), findsOneWidget);
      expect(find.text('remove me'), findsOneWidget);
      await tester.tap(find.text(t.common.cancel));
      await tester.pumpAndSettle();
      expect(find.text('remove me'), findsOneWidget);
      await tester.longPress(find.text('remove me'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(t.common.delete));
      await tester.pumpAndSettle();
      await tester.tap(find.text(t.common.delete));
      await tester.pumpAndSettle();
      expect(find.text('remove me'), findsNothing);
      expect(find.byType(MessageBubble), findsNWidgets(3));
    });

    testWidgets('photo long press opens a matching popover and deletes it', (
      tester,
    ) async {
      await tester.pumpApp(
        messages: FakeMessageRepository(
          seed: [
            testMessage(1, '', images: ['media/missing.jpg']),
          ],
        ),
      );
      final photo = find.byType(MessageImageStack);
      final anchor = tester.getCenter(photo);
      await tester.longPressAt(anchor);
      await tester.pumpAndSettle();

      expect(find.text(t.common.copy), findsNothing);
      expect(find.text(t.common.selectText), findsNothing);
      final surface = find.byKey(const ValueKey('app-popover-surface'));
      expect(tester.getRect(surface).bottom, closeTo(anchor.dy - 8, 1));
      await tester.tap(find.text(t.common.delete));
      await tester.pumpAndSettle();
      expect(find.byType(AppConfirmDialog), findsOneWidget);
      expect(photo, findsOneWidget);
      await tester.tap(find.text(t.common.delete));
      await tester.pumpAndSettle();
      expect(photo, findsNothing);
      expect(find.byType(AppActionPopover), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });
}
