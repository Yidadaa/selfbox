import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:selfbox/core/testing/app_widget_tester.dart';
import 'package:selfbox/core/theme/app_glass_theme.dart';
import 'package:selfbox/core/theme/app_radius.dart';
import 'package:selfbox/core/theme/app_spacing.dart';
import 'package:selfbox/core/theme/message_tokens.dart';
import 'package:selfbox/features/chat/domain/models/message.dart';
import 'package:selfbox/features/chat/presentation/widgets/message_bubble.dart';
import 'package:selfbox/features/chat/presentation/widgets/message_image_stack.dart';

void main() {
  setUpAll(initializeDateFormatting);
  for (final author in MessageAuthor.values) {
    testWidgets('$author keeps the timestamp below the bubble', (tester) async {
      await tester.pumpPage(
        MessageBubble(
          message: Message(
            id: 1,
            createdAt: DateTime(2026, 11, 12, 9, 30),
            author: author,
            text: 'Hello',
          ),
          resolveImage: (_) => null,
        ),
      );
      final surface = tester.getRect(
        find.byKey(const ValueKey('message-surface')),
      );
      final time = tester.getRect(find.text('09:30'));
      expect(find.byIcon(Icons.auto_awesome), findsNothing);
      expect(time.top, greaterThan(surface.bottom));
      expect(surface.contains(time.topLeft), isFalse);
      expect(
        time.top,
        greaterThan(
          tester.getBottomLeft(find.text('Hello', findRichText: true)).dy,
        ),
      );
    });
  }
  for (final brightness in Brightness.values) {
    for (final author in MessageAuthor.values) {
      for (final content in ['text', 'photo', 'caption']) {
        testWidgets('$brightness $author $content has an external footer', (
          tester,
        ) async {
          var longPressed = false;
          await tester.pumpPage(
            Center(
              child: MessageBubble(
                message: Message(
                  id: 1,
                  createdAt: DateTime(2026, 11, 12, 9, 30),
                  author: author,
                  text: content == 'photo' ? '' : 'Hello',
                  images: content == 'text' ? [] : ['media/missing.png'],
                  askedAi: true,
                ),
                resolveImage: (_) => null,
                onLongPress: () => longPressed = true,
              ),
            ),
            brightness: brightness,
          );
          final time = tester.getRect(find.text('09:30'));
          final status = tester.getRect(find.byIcon(Icons.auto_awesome));
          final contentFinder = content == 'photo'
              ? find.byType(MessageImageStack)
              : find.byKey(const ValueKey('message-surface'));
          final surface = tester.getRect(contentFinder);
          expect(time.top, greaterThan(surface.bottom));
          expect(status.top, greaterThan(surface.bottom));
          expect(status.center.dy, closeTo(time.center.dy, 0.01));
          expect(
            tester.widget<Text>(find.text('09:30')).style?.color,
            AppGlassTheme.of(brightness).foregroundMuted,
          );
          switch (author) {
            case MessageAuthor.me:
              expect(time.right, lessThanOrEqualTo(surface.right));
              expect(time.right, greaterThan(surface.right - AppSpacing.md));
            case MessageAuthor.ai:
              expect(status.left, greaterThanOrEqualTo(surface.left));
              expect(status.left, lessThan(surface.left + AppSpacing.md));
          }
          if (content != 'text') {
            final image = find.byType(MessageImageStack);
            expect(
              find.descendant(
                of: find.byKey(const ValueKey('message-surface')),
                matching: image,
              ),
              findsNothing,
            );
            expect(
              find.descendant(of: image, matching: find.byType(GlassContainer)),
              findsOneWidget,
            );
            if (content == 'photo') {
              expect(
                find.byKey(const ValueKey('message-surface')),
                findsNothing,
              );
            } else {
              expect(tester.getBottomLeft(image).dy, lessThan(surface.top));
            }
          }
          await tester.longPress(contentFinder);
          expect(longPressed, isTrue);
          expect(tester.takeException(), isNull);
        });
      }
    }
  }
  test('outgoing bubbles are blue with white text in both themes', () {
    for (final glass in [AppGlassTheme.dark, AppGlassTheme.light]) {
      expect(glass.bubbleMine, const Color(0xFF006FE6));
      expect(glass.onBubbleMine, Colors.white);
    }
  });
  for (final count in [1, 2, 6]) {
    testWidgets('$count images occupy one bounded stack', (tester) async {
      String? opened;
      final images = List.generate(count, (i) => 'media/$i.png');
      await tester.pumpPage(
        Center(
          child: MessageBubble(
            message: Message(
              id: 1,
              createdAt: kTestNow,
              author: MessageAuthor.me,
              text: '',
              images: images,
            ),
            resolveImage: (_) => null,
            onImageTap: (path) => opened = path,
          ),
        ),
      );
      final stack = find.byType(MessageImageStack);
      final frames = find.descendant(
        of: stack,
        matching: find.byType(GlassContainer),
      );
      expect(frames, findsNWidgets(count.clamp(1, 3)));
      for (final frame in tester.widgetList<GlassContainer>(frames)) {
        expect(frame.quality, GlassQuality.standard);
        expect(frame.padding, const EdgeInsets.all(AppSpacing.xxs));
        expect(
          frame.shape,
          isA<LiquidRoundedSuperellipse>().having(
            (shape) => shape.borderRadius,
            'concentric radius',
            MessageTokens.imageFrameRadius,
          ),
        );
      }
      expect(tester.getSize(stack).width, lessThanOrEqualTo(240));
      expect(tester.getSize(stack).height, lessThanOrEqualTo(220));
      await tester.tap(stack);
      expect(opened, images.first);
      expect(tester.takeException(), isNull);
    });
  }
  test('photo frame and image corners are concentric', () {
    expect(
      MessageTokens.imageFrameRadius - MessageTokens.imageFramePadding,
      AppRadius.sm,
    );
  });
  testWidgets('narrow screen keeps a photo caption and footer within bounds', (
    tester,
  ) async {
    await tester.pumpPage(
      SingleChildScrollView(
        child: MessageBubble(
          message: Message(
            id: 1,
            createdAt: kTestNow,
            author: MessageAuthor.me,
            text: 'A longer photo caption that wraps across several lines.',
            images: List.generate(6, (index) => 'media/$index.png'),
            askedAi: true,
          ),
          resolveImage: (_) => null,
        ),
      ),
    );
    tester.view.physicalSize = const Size(280 * 3, 640 * 3);
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpAndSettle();
    for (final finder in [
      find.byType(MessageImageStack),
      find.byKey(const ValueKey('message-surface')),
      find.text('10:00'),
    ]) {
      final rect = tester.getRect(finder);
      expect(rect.left, greaterThanOrEqualTo(0));
      expect(rect.right, lessThanOrEqualTo(280));
    }
    expect(tester.takeException(), isNull);
  });
}
