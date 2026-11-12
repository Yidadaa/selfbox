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
          if (content != 'photo') {
            final material = tester.widget(contentFinder);
            switch (author) {
              case MessageAuthor.me:
                expect(
                  material,
                  isA<ColoredBox>().having(
                    (box) => box.color,
                    'outgoing color',
                    AppGlassTheme.of(brightness).bubbleMine,
                  ),
                );
              case MessageAuthor.ai:
                expect(
                  material,
                  isA<DecoratedBox>().having(
                    (box) => box.decoration,
                    'theme card without shadow',
                    isA<ShapeDecoration>()
                        .having(
                          (decoration) => decoration.color,
                          'color',
                          AppGlassTheme.of(brightness).bubbleOther,
                        )
                        .having(
                          (decoration) => decoration.shadows,
                          'shadows',
                          isNull,
                        ),
                  ),
                );
                expect(
                  find.descendant(
                    of: contentFinder,
                    matching: find.byType(GlassContainer),
                  ),
                  findsNothing,
                );
            }
          }
          expect(time.top, greaterThan(surface.bottom));
          expect(status.top, greaterThan(surface.bottom));
          expect(status.center.dy, closeTo(time.center.dy, 0.01));
          expect(
            tester.widget<Text>(find.text('09:30')).style?.color,
            AppGlassTheme.of(brightness).messageMetadata,
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
            final frames = find.descendant(
              of: image,
              matching: find.byType(DecoratedBox),
            );
            expect(frames, findsOneWidget);
            final frame = tester.widget<DecoratedBox>(frames.first);
            expect(
              frame.decoration,
              isA<ShapeDecoration>()
                  .having(
                    (shape) => shape.color,
                    'theme surface',
                    AppGlassTheme.of(brightness).bubbleOther,
                  )
                  .having((shape) => shape.shadows, 'shadows', isNull),
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
  for (final brightness in Brightness.values) {
    for (final count in [1, 2, 6]) {
      testWidgets('$brightness $count images occupy one bounded stack', (
        tester,
      ) async {
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
          brightness: brightness,
        );
        final stack = find.byType(MessageImageStack);
        final frames = find.descendant(
          of: stack,
          matching: find.byWidgetPredicate(
            (widget) =>
                widget is DecoratedBox && widget.decoration is ShapeDecoration,
          ),
        );
        expect(frames, findsNWidgets(count.clamp(1, 3)));
        for (final frame in tester.widgetList<DecoratedBox>(frames)) {
          final decoration = frame.decoration as ShapeDecoration;
          expect(decoration.color, AppGlassTheme.of(brightness).bubbleOther);
          expect(decoration.shadows, isNull);
          expect(
            decoration.shape,
            isA<RoundedSuperellipseBorder>().having(
              (shape) => shape.borderRadius,
              'radius',
              BorderRadius.circular(MessageTokens.imageFrameRadius),
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
