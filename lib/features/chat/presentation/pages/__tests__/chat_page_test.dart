import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:selfbox/core/router/app_router.dart';
import 'package:selfbox/core/testing/app_widget_tester.dart';
import 'package:selfbox/core/testing/fake_message_repository.dart';
import 'package:selfbox/core/theme/app_spacing.dart';
import 'package:selfbox/core/widgets/pressable.dart';
import 'package:selfbox/features/chat/domain/models/message.dart';
import 'package:selfbox/features/chat/presentation/pages/image_viewer_page.dart';
import 'package:selfbox/features/chat/presentation/providers/chat_feed.dart';
import 'package:selfbox/features/chat/presentation/widgets/chat_composer.dart';
import 'package:selfbox/features/chat/presentation/widgets/day_pill.dart';
import 'package:selfbox/features/chat/presentation/widgets/message_bubble.dart';
import 'package:selfbox/gen/i18n/strings.g.dart';
import 'package:skeletonizer/skeletonizer.dart';

Message _msg(
  int id,
  String text, {
  MessageAuthor author = MessageAuthor.me,
  DateTime? at,
  List<String> images = const [],
}) => Message(
  id: id,
  createdAt: at ?? kTestNow.subtract(Duration(minutes: 10 - id)),
  author: author,
  text: text,
  images: images,
);

Finder _composerField() => find.descendant(
  of: find.byType(ChatComposer),
  matching: find.byType(EditableText),
);

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
                : Stream.value([_msg(1, 'recovered')]),
          ),
        ],
      );
      await tester.enterText(_composerField(), 'keep this draft');
      await tester.pump();
      await tester.tap(find.text(t.common.retry));
      await tester.pumpAndSettle();
      expect(find.text('recovered'), findsOneWidget);
      expect(
        tester.widget<EditableText>(_composerField()).controller.text,
        'keep this draft',
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('shows the empty state with the composer', (tester) async {
      await tester.pumpApp();

      expect(find.text(t.chat.empty), findsOneWidget);
      expect(find.byType(ChatComposer), findsOneWidget);
    });

    testWidgets('puts my notes on the right and AI replies on the left', (
      tester,
    ) async {
      await tester.pumpApp(
        messages: FakeMessageRepository(
          seed: [
            _msg(1, 'mine'),
            _msg(2, 'from ai', author: MessageAuthor.ai),
          ],
        ),
      );

      final width =
          tester.view.physicalSize.width / tester.view.devicePixelRatio;
      expect(tester.getCenter(find.text('mine')).dx, greaterThan(width / 2));
      expect(
        tester.getCenter(find.text('from ai', findRichText: true)).dx,
        lessThan(width / 2),
      );
    });

    testWidgets('with the keyboard open the composer sits right above it', (
      tester,
    ) async {
      await tester.pumpApp();
      const keyboard = 300.0;
      tester.view.viewInsets = const FakeViewPadding(bottom: keyboard * 3);
      await tester.pumpAndSettle();

      final composerBottom = tester.getBottomLeft(find.byType(ChatComposer)).dy;
      final keyboardTop = kPhoneViewport.height - keyboard;
      expect(composerBottom, lessThanOrEqualTo(keyboardTop));
      expect(composerBottom, greaterThan(keyboardTop - AppSpacing.md));
    });

    testWidgets('marks notes that were sent to the AI', (tester) async {
      await tester.pumpApp(
        messages: FakeMessageRepository(
          seed: [_msg(1, 'plain'), _msg(2, 'asked').copyWith(askedAi: true)],
        ),
      );
      // Filled sparkle = AI question mark (the composer toggle is outlined).
      expect(
        find.descendant(
          of: find.byType(MessageBubble),
          matching: find.byIcon(Icons.auto_awesome),
        ),
        findsOneWidget,
      );
    });

    testWidgets('groups messages under day pills', (tester) async {
      await tester.pumpApp(
        messages: FakeMessageRepository(
          seed: [
            _msg(1, 'old', at: DateTime(2026, 11, 11, 9)),
            _msg(2, 'new', at: DateTime(2026, 11, 12, 9)),
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

    testWidgets('typing and sending adds a note to the timeline', (
      tester,
    ) async {
      final messages = FakeMessageRepository();
      await tester.pumpApp(messages: messages);

      await tester.enterText(_composerField(), '周末想去爬山');
      await tester.pump();
      await tester.tap(find.bySemanticsLabel(t.chat.send));
      await tester.pumpAndSettle();

      expect(messages.added.single.text, '周末想去爬山');
      expect(
        find.descendant(
          of: find.byType(MessageBubble),
          matching: find.text('周末想去爬山'),
        ),
        findsOneWidget,
      );
      expect(
        tester.widget<EditableText>(_composerField()).controller.text,
        isEmpty,
      );
    });

    testWidgets('the AI toggle switches the placeholder', (tester) async {
      await tester.pumpApp();
      expect(find.text(t.chat.inputHint), findsOneWidget);

      await tester.tap(find.bySemanticsLabel(t.chat.aiMode));
      await tester.pumpAndSettle();

      expect(find.text(t.chat.aiInputHint), findsOneWidget);
      expect(find.byIcon(Icons.auto_awesome), findsWidgets);
    });

    testWidgets('long-press offers copy and delete; delete removes it', (
      tester,
    ) async {
      final messages = FakeMessageRepository(seed: [_msg(1, 'remove me')]);
      await tester.pumpApp(messages: messages);

      await tester.longPress(find.text('remove me'));
      await tester.pumpAndSettle();
      expect(find.text(t.common.copy), findsOneWidget);

      await tester.tap(find.text(t.common.delete));
      await tester.pumpAndSettle();

      expect(find.text('remove me'), findsNothing);
      expect(find.text(t.chat.empty), findsOneWidget);
    });

    testWidgets('tapping an image opens the full-screen viewer', (
      tester,
    ) async {
      final container = await tester.pumpApp(
        messages: FakeMessageRepository(
          seed: [
            _msg(1, '', images: ['media/missing.jpg']),
          ],
        ),
      );

      await tester.tap(
        find.descendant(
          of: find.byType(MessageBubble),
          matching: find.byType(Pressable),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ImageViewerPage), findsOneWidget);
      expect(
        container.read(appRouterProvider).state.uri.toString(),
        '/image?path=media%2Fmissing.jpg',
      );

      await tester.tap(find.byType(GlassIconButton));
      await tester.pumpAndSettle();
      expect(find.byType(ImageViewerPage), findsNothing);
    });
  });
}
