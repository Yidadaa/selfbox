import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:selfbox/core/error/app_failure.dart';
import 'package:selfbox/core/router/app_router.dart';
import 'package:selfbox/core/testing/app_widget_tester.dart';
import 'package:selfbox/core/testing/fake_message_repository.dart';
import 'package:selfbox/core/theme/app_glass_theme.dart';
import 'package:selfbox/core/theme/app_spacing.dart';
import 'package:selfbox/core/widgets/app_confirm_dialog.dart';
import 'package:selfbox/core/widgets/empty_state.dart';
import 'package:selfbox/core/widgets/pressable.dart';
import 'package:selfbox/features/chat/domain/models/message.dart';
import 'package:selfbox/features/chat/presentation/pages/chat_page.dart';
import 'package:selfbox/features/chat/presentation/pages/image_viewer_page.dart';
import 'package:selfbox/features/chat/presentation/pages/message_search_page.dart';
import 'package:selfbox/features/chat/presentation/providers/chat_feed.dart';
import 'package:selfbox/features/chat/presentation/providers/composer_controller.dart';
import 'package:selfbox/features/chat/presentation/providers/message_search.dart';
import 'package:selfbox/features/chat/presentation/widgets/chat_composer.dart';
import 'package:selfbox/features/chat/presentation/widgets/day_pill.dart';
import 'package:selfbox/features/chat/presentation/widgets/message_bubble.dart';
import 'package:selfbox/features/chat/presentation/widgets/message_image_stack.dart';
import 'package:selfbox/features/chat/presentation/widgets/outgoing_message_entrance.dart';
import 'package:selfbox/features/chat/presentation/widgets/welcome_timeline.dart';
import 'package:selfbox/features/settings/presentation/pages/me_page.dart';
import 'package:selfbox/features/settings/presentation/pages/profile_page.dart';
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

class _SingleImagePicker extends Fake implements ImagePicker {
  @override
  Future<List<XFile>> pickMultiImage({
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    int? limit,
    bool requestFullMetadata = true,
  }) async => [
    XFile.fromData(
      Uint8List.fromList([1]),
      name: 'photo.png',
      path: 'photo.png',
    ),
  ];
}

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

    testWidgets('header opens settings, profile, and message search', (
      tester,
    ) async {
      final container = await tester.pumpApp();
      tester.view.physicalSize = const Size(320 * 3, 844 * 3);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(
        tester.widget<GlassAppBar>(find.byType(GlassAppBar)).toolbarHeight,
        AppSizes.chatHeaderHeight,
      );
      expect(
        tester
            .widgetList<GlassIconButton>(find.byType(GlassIconButton))
            .every((button) => button.quality == GlassQuality.premium),
        isTrue,
      );
      expect(
        tester
            .widget<GlassContainer>(
              find.byKey(const ValueKey('chat-header-profile-surface')),
            )
            .quality,
        GlassQuality.premium,
      );
      final avatar = tester.getRect(
        find.byKey(const ValueKey('chat-header-avatar')),
      );
      final name = tester.getRect(
        find.byKey(const ValueKey('chat-header-profile-surface')),
      );
      expect(avatar.width, greaterThan(44));
      expect(avatar.center.dx, closeTo(name.center.dx, 0.01));
      expect(name.top, lessThan(avatar.bottom));
      expect(name.center.dy, greaterThan(avatar.center.dy));
      expect(
        tester.widget<Text>(find.text(t.me.defaultName)).style?.fontSize,
        lessThan(18),
      );
      final profileStack = tester.widget<Stack>(
        find
            .ancestor(
              of: find.byKey(const ValueKey('chat-header-avatar')),
              matching: find.byType(Stack),
            )
            .first,
      );
      expect(
        (profileStack.children.last as Positioned).child.key,
        const ValueKey('chat-header-avatar'),
      );

      await tester.tap(find.bySemanticsLabel(t.chat.openSettings));
      await tester.pumpAndSettle();
      expect(find.byType(MePage), findsOneWidget);
      container.read(appRouterProvider).go('/chat');
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('chat-header-profile')));
      await tester.pumpAndSettle();
      expect(find.byType(ProfilePage), findsOneWidget);
      container.read(appRouterProvider).go('/chat');
      await tester.pumpAndSettle();

      await tester.tap(find.bySemanticsLabel(t.chat.searchMessages));
      await tester.pumpAndSettle();
      expect(find.byType(MessageSearchPage), findsOneWidget);
    });

    testWidgets('the timeline scrolls behind the profile header', (
      tester,
    ) async {
      await tester.pumpApp(
        messages: FakeMessageRepository(
          seed: [for (var id = 1; id <= 12; id++) _msg(id, 'Note $id')],
        ),
      );

      final timeline = find.descendant(
        of: find.byType(ChatPage),
        matching: find.byType(ListView),
      );
      expect(timeline, findsOneWidget);
      expect(tester.getRect(timeline).top, 0);
      final list = tester.widget<ListView>(timeline);
      final safeTop = MediaQuery.paddingOf(tester.element(timeline)).top;
      expect(
        (list.padding! as EdgeInsets).top,
        safeTop + AppSizes.chatHeaderHeight + AppSpacing.md,
      );
    });

    testWidgets('message search filters notes and shows an empty result', (
      tester,
    ) async {
      await tester.pumpApp(
        messages: FakeMessageRepository(
          seed: [_msg(1, 'weekly report'), _msg(2, 'weekend hike')],
        ),
      );
      await tester.tap(find.bySemanticsLabel(t.chat.searchMessages));
      await tester.pumpAndSettle();
      expect(find.text('Search your thoughts'), findsOneWidget);
      expect(
        find.ancestor(
          of: find.text('Search your thoughts'),
          matching: find.byType(GlassContainer),
        ),
        findsNothing,
      );

      await tester.enterText(
        find.byKey(const ValueKey('message-search-input')),
        'report',
      );
      await tester.pumpAndSettle();
      expect(find.text('weekly report'), findsOneWidget);
      expect(find.text('weekend hike'), findsNothing);

      await tester.enterText(
        find.byKey(const ValueKey('message-search-input')),
        'missing phrase',
      );
      await tester.pumpAndSettle();
      expect(find.text(t.chat.noSearchResults), findsOneWidget);
      expect(
        find.ancestor(
          of: find.text(t.chat.noSearchResults),
          matching: find.byType(GlassContainer),
        ),
        findsNothing,
      );
    });

    testWidgets('search has the requested Chinese empty-state copy', (
      tester,
    ) async {
      await tester.pumpApp(locale: AppLocale.zhCn);
      await tester.tap(find.bySemanticsLabel(t.chat.searchMessages));
      await tester.pumpAndSettle();
      expect(find.text('搜索你的碎碎念'), findsOneWidget);

      await tester.enterText(
        find.byKey(const ValueKey('message-search-input')),
        '没有的内容',
      );
      await tester.pumpAndSettle();
      expect(find.text('没有搜索到消息'), findsOneWidget);
    });

    testWidgets('message search failures offer a retry action', (tester) async {
      await tester.pumpApp(
        overrides: [
          messageSearchProvider('broken').overrideWith(
            (ref) async =>
                const Left(AppFailure.database(message: 'unavailable')),
          ),
        ],
      );
      await tester.tap(find.bySemanticsLabel(t.chat.searchMessages));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('message-search-input')),
        'broken',
      );
      await tester.pumpAndSettle();

      expect(find.text(t.settings.errors.generic), findsOneWidget);
      expect(find.text(t.common.retry), findsOneWidget);
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

    testWidgets('only a newly sent bubble enters from the composer', (
      tester,
    ) async {
      final messages = FakeMessageRepository(seed: [_msg(1, 'older')]);
      await tester.pumpApp(messages: messages);
      expect(find.byType(OutgoingMessageEntrance), findsNothing);

      await tester.enterText(_composerField(), 'new note');
      await tester.pump();
      await tester.tap(find.bySemanticsLabel(t.chat.send));
      await tester.pump();
      await tester.pump();

      final incoming = find.ancestor(
        of: find.text('new note'),
        matching: find.byType(OutgoingMessageEntrance),
      );
      expect(incoming, findsOneWidget);
      expect(
        tester
            .widget<SizeTransition>(
              find.descendant(
                of: incoming,
                matching: find.byType(SizeTransition),
              ),
            )
            .sizeFactor
            .value,
        lessThan(1),
      );
      expect(find.text('older'), findsOneWidget);

      await tester.pumpAndSettle();
      expect(find.byType(OutgoingMessageEntrance), findsNothing);
      expect(find.text('new note'), findsOneWidget);
    });

    testWidgets('incoming AI messages do not replay the send entrance', (
      tester,
    ) async {
      final messages = FakeMessageRepository(seed: [_msg(1, 'older')]);
      await tester.pumpApp(messages: messages);
      await messages
          .add(const MessageDraft(author: MessageAuthor.ai, text: 'reply'))
          .run();
      await tester.pumpAndSettle();

      expect(find.byType(OutgoingMessageEntrance), findsNothing);
      expect(find.text('reply', findRichText: true), findsOneWidget);
    });

    testWidgets('the first sent message enters after welcome', (tester) async {
      final container = await tester.pumpApp(messages: FakeMessageRepository());
      await tester.enterText(_composerField(), 'first note');
      await tester.pump();
      await tester.tap(find.bySemanticsLabel(t.chat.send));
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));

      expect(container.read(composerControllerProvider).lastSentMessageId, 1);
      expect(container.read(chatFeedProvider), isA<AsyncData<ChatFeed>>());
      expect(find.byType(WelcomeTimeline), findsNothing);
      expect(find.byType(OutgoingMessageEntrance), findsOneWidget);
      expect(find.text('first note'), findsOneWidget);

      expect(
        find.ancestor(
          of: find.text('first note'),
          matching: find.byType(OutgoingMessageEntrance),
        ),
        findsOneWidget,
      );
      await tester.pumpAndSettle();
      expect(find.text('first note'), findsOneWidget);
    });

    testWidgets('quick successive sends each enter once', (tester) async {
      var tick = 0;
      await tester.pumpApp(
        messages: FakeMessageRepository(
          seed: [_msg(1, 'older')],
          clock: () => kTestNow.add(Duration(seconds: tick++)),
        ),
      );

      await tester.enterText(_composerField(), 'one');
      await tester.pump();
      await tester.tap(find.bySemanticsLabel(t.chat.send));
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));
      expect(find.byType(OutgoingMessageEntrance), findsOneWidget);

      await tester.enterText(_composerField(), 'two');
      await tester.pump();
      await tester.tap(find.bySemanticsLabel(t.chat.send));
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));
      expect(find.byType(OutgoingMessageEntrance), findsNWidgets(2));
      expect(find.text('older'), findsOneWidget);

      await tester.pumpAndSettle();
      expect(find.byType(OutgoingMessageEntrance), findsNothing);
      expect(find.text('one'), findsOneWidget);
      expect(find.text('two'), findsOneWidget);
    });

    testWidgets('an image-only send uses the same entrance', (tester) async {
      final container = await tester.pumpApp(
        overrides: [
          imagePickerProvider.overrideWithValue(_SingleImagePicker()),
        ],
        messages: FakeMessageRepository(seed: [_msg(1, 'older')]),
      );
      await tester.runAsync(
        () => container.read(composerControllerProvider.notifier).pickImage(),
      );
      await tester.pump();
      await tester.tap(find.bySemanticsLabel(t.chat.send));
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));

      expect(
        find.ancestor(
          of: find.byType(MessageImageStack).last,
          matching: find.byType(OutgoingMessageEntrance),
        ),
        findsOneWidget,
      );
      await tester.pumpAndSettle();
      expect(find.byType(OutgoingMessageEntrance), findsNothing);
    });

    testWidgets('sending while reading older notes returns to the newest row', (
      tester,
    ) async {
      await tester.pumpApp(
        messages: FakeMessageRepository(
          seed: [for (var id = 1; id <= 40; id++) _msg(id, 'Note $id')],
          clock: () => kTestNow.add(const Duration(hours: 1)),
        ),
      );
      final timeline = find.descendant(
        of: find.byType(ChatPage),
        matching: find.byType(ListView),
      );
      final scrollable = find.descendant(
        of: timeline,
        matching: find.byType(Scrollable),
      );
      await tester.drag(timeline, const Offset(0, 400));
      await tester.pumpAndSettle();
      expect(
        tester.state<ScrollableState>(scrollable).position.pixels,
        greaterThan(0),
      );

      await tester.enterText(_composerField(), 'newest');
      await tester.pump();
      await tester.tap(find.bySemanticsLabel(t.chat.send));
      await tester.pumpAndSettle();

      expect(
        tester.state<ScrollableState>(scrollable).position.pixels,
        closeTo(0, 0.1),
      );
      expect(find.text('newest'), findsOneWidget);
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
      expect(find.byType(AppActionDialog), findsOneWidget);
      expect(find.text(t.common.copy), findsOneWidget);

      await tester.tap(find.text(t.common.cancel));
      await tester.pumpAndSettle();
      expect(find.text('remove me'), findsOneWidget);

      await tester.longPress(find.text('remove me'));
      await tester.pumpAndSettle();

      await tester.tap(find.text(t.common.delete));
      await tester.pumpAndSettle();

      expect(find.text('remove me'), findsNothing);
      expect(find.byType(MessageBubble), findsNWidgets(3));
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

    testWidgets('unavailable image uses readable text on the dark viewer', (
      tester,
    ) async {
      final container = await tester.pumpApp();
      container.read(appRouterProvider).go('/image?path=outside.jpg');
      await tester.pumpAndSettle();

      final label = find.text(t.chat.imageFailed);
      expect(label, findsOneWidget);
      expect(
        tester.widget<Text>(label).style?.color,
        AppGlassTheme.dark.foregroundMuted,
      );
      expect(find.byIcon(Icons.broken_image_outlined), findsNothing);
    });
  });
}
