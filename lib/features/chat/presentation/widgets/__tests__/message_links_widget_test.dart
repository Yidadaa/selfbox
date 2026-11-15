import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:selfbox/core/error/app_failure.dart';
import 'package:selfbox/core/platform/external_browser.dart';
import 'package:selfbox/core/testing/app_widget_tester.dart';
import 'package:selfbox/core/testing/fake_message_repository.dart';
import 'package:selfbox/core/testing/icon_finder.dart';
import 'package:selfbox/core/theme/app_glass_theme.dart';
import 'package:selfbox/core/theme/app_icons.dart';
import 'package:selfbox/core/theme/app_spacing.dart';
import 'package:selfbox/core/widgets/app_action_popover.dart';
import 'package:selfbox/core/widgets/app_icon.dart';
import 'package:selfbox/features/chat/domain/models/message.dart';
import 'package:selfbox/features/chat/domain/repositories/web_research_repository.dart';
import 'package:selfbox/features/chat/presentation/providers/message_link_preview.dart';
import 'package:selfbox/features/chat/presentation/widgets/message_bubble.dart';
import 'package:selfbox/features/chat/presentation/widgets/message_text_content.dart';
import 'package:selfbox/gen/i18n/strings.g.dart';

Message _message(String text) =>
    Message(id: 1, createdAt: kTestNow, author: MessageAuthor.me, text: text);

void main() {
  setUpAll(initializeDateFormatting);
  testWidgets(
    'bookmark long press opens message actions and preserves source selection',
    (tester) async {
      final opened = <Uri>[];
      await tester.pumpApp(
        messages: FakeMessageRepository(
          seed: [_message('https://example.com')],
        ),
        overrides: [
          externalBrowserProvider.overrideWithValue(
            ExternalBrowser(
              launch: (uri) async {
                opened.add(uri);
                return true;
              },
            ),
          ),
        ],
      );
      await tester.longPress(find.byKey(const ValueKey('message-bookmark')));
      await tester.pumpAndSettle();
      expect(find.byType(AppActionPopover), findsOneWidget);
      expect(opened, isEmpty);
      await tester.tap(find.text(t.common.selectText));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('message-bookmark')), findsNothing);
      expect(find.byType(MessageTextContent), findsOneWidget);
      expect(opened, isEmpty);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    },
  );
  testWidgets('inline links preserve literal text and open externally', (
    tester,
  ) async {
    final opened = <Uri>[];
    const text = '**literal** https://example.com，下一段';
    await tester.pumpPage(
      Center(
        child: MessageTextContent(
          message: _message(text),
          selectionMode: false,
        ),
      ),
      overrides: [
        externalBrowserProvider.overrideWithValue(
          ExternalBrowser(
            launch: (uri) async {
              opened.add(uri);
              return true;
            },
          ),
        ),
      ],
    );
    final rich = find.byWidgetPredicate(
      (w) => w is RichText && w.text.toPlainText() == text,
    );
    final paragraph = tester.renderObject<RenderParagraph>(rich);
    final boxes = paragraph.getBoxesForSelection(
      TextSelection(
        baseOffset: text.indexOf('https'),
        extentOffset: text.indexOf('https') + 5,
      ),
    );
    await tester.tapAt(paragraph.localToGlobal(boxes.first.toRect().center));
    await tester.pump();
    expect(opened, [Uri.parse('https://example.com')]);
  });
  for (final brightness in Brightness.values) {
    testWidgets('links and bookmark fit narrow large text in $brightness', (
      tester,
    ) async {
      await tester.pumpPage(
        SingleChildScrollView(
          child: Column(
            children: [
              MessageBubble(
                message: _message('Read https://example.com now'),
                resolveImage: (_) => null,
              ),
              MessageBubble(
                message: _message('https://example.com')
                    .copyWith(askedAi: true, quotedMessageIds: [2]),
                resolveImage: (_) => null,
              ),
            ],
          ),
        ),
        brightness: brightness,
      );
      tester.view.physicalSize = const Size(280 * 3, 844 * 3);
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpAndSettle();
      final card = tester.getRect(
        find.byKey(const ValueKey('message-bookmark')),
      );
      expect(card.left, greaterThanOrEqualTo(0));
      expect(card.right, lessThanOrEqualTo(280));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    });
    testWidgets(
      'bookmark loading, metadata and fallback keep size in $brightness',
      (tester) async {
        final pending = Completer<Either<AppFailure, WebPageContent>>();
        var failed = false;
        final opened = <Uri>[];
        const url = 'https://example.com/story';
        final container = await tester.pumpPage(
          Center(
            child: MessageBubble(
              message: _message(url),
              resolveImage: (_) => null,
            ),
          ),
          brightness: brightness,
          settle: false,
          overrides: [
            messageLinkPreviewProvider(url).overrideWith(
              (ref) => failed
                  ? Future.value(
                      const Left(AppFailure.network(message: 'offline')),
                    )
                  : pending.future,
            ),
            externalBrowserProvider.overrideWithValue(
              ExternalBrowser(
                launch: (uri) async {
                  opened.add(uri);
                  return true;
                },
              ),
            ),
          ],
        );
        final card = find.byKey(const ValueKey('message-bookmark'));
        final loadingSize = tester.getSize(card);
        pending.complete(
          const Right(
            WebPageContent(
              title: 'Article title',
              url: url,
              text: 'body',
              description: 'A short summary',
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Article title'), findsOneWidget);
        expect(find.text('A short summary'), findsOneWidget);
        final title = find.text('Article title');
        final summary = find.text('A short summary');
        expect(tester.widget<Text>(title).maxLines, 1);
        expect(tester.widget<Text>(summary).maxLines, 1);
        expect(tester.widget<Text>(title).overflow, TextOverflow.ellipsis);
        expect(tester.widget<Text>(summary).overflow, TextOverflow.ellipsis);
        expect(
          tester.getTopLeft(summary).dy - tester.getBottomLeft(title).dy,
          AppSpacing.xxs,
        );
        expect(tester.widget<AppIcon>(findAppIcon(AppIcons.webRead)).size, 16);
        final glass = tester.element(card).glass;
        expect(
          find.descendant(
            of: card,
            matching: find.byWidgetPredicate(
              (widget) =>
                  widget is ColoredBox && widget.color == glass.bubbleMine,
            ),
          ),
          findsOneWidget,
        );
        expect(tester.widget<Text>(title).style?.color, glass.onBubbleMine);
        expect(tester.getSize(card).height, lessThan(100));
        expect(tester.getSize(card), loadingSize);
        await tester.tap(card);
        await tester.pumpAndSettle();
        expect(opened.single.toString(), url);
        failed = true;
        container.invalidate(messageLinkPreviewProvider(url));
        await tester.pumpAndSettle();
        expect(find.text(t.chat.linkPreviewUnavailable), findsOneWidget);
        expect(tester.getSize(card), loadingSize);
      },
    );
    testWidgets('quote, AI and timestamp share one row in $brightness', (
      tester,
    ) async {
      var tapped = false;
      await tester.pumpPage(
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              MessageBubble(
                key: const ValueKey('with-quote'),
                message: _message('Hello')
                    .copyWith(askedAi: true, quotedMessageIds: [2, 3]),
                resolveImage: (_) => null,
                onQuoteTap: () => tapped = true,
              ),
              MessageBubble(
                key: const ValueKey('time-only'),
                message: _message('Hello'),
                resolveImage: (_) => null,
              ),
            ],
          ),
        ),
        brightness: brightness,
      );
      final quote = find.text(t.chat.quotedCount(count: 2));
      final quotedBubble = find.byKey(const ValueKey('with-quote'));
      final timeBubble = find.byKey(const ValueKey('time-only'));
      final quotedTime = find.descendant(
        of: quotedBubble,
        matching: find.text('10:00'),
      );
      final plainTime = find.descendant(
        of: timeBubble,
        matching: find.text('10:00'),
      );
      final quotedSurface = find.descendant(
        of: quotedBubble,
        matching: find.byKey(const ValueKey('message-surface')),
      );
      final plainSurface = find.descendant(
        of: timeBubble,
        matching: find.byKey(const ValueKey('message-surface')),
      );
      final plainGap =
          tester.getTopLeft(plainTime).dy -
          tester.getBottomLeft(plainSurface).dy;
      expect(
        tester.getTopLeft(quote).dy - tester.getBottomLeft(quotedSurface).dy,
        closeTo(plainGap, 0.1),
      );
      expect(
        tester.getTopLeft(quotedTime).dy -
            tester.getBottomLeft(quotedSurface).dy,
        closeTo(plainGap, 0.1),
      );
      expect(
        tester.getSize(quotedBubble).height,
        tester.getSize(timeBubble).height,
      );
      final y = tester.getCenter(quote).dy;
      expect(tester.getCenter(findAppIcon(AppIcons.ai)).dy, closeTo(y, 0.1));
      expect(tester.getCenter(quotedTime).dy, closeTo(y, 0.1));
      await tester.tap(quote);
      expect(tapped, isTrue);
    });
  }
}
