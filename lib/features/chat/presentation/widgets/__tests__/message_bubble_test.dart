import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:selfbox/core/testing/app_widget_tester.dart';
import 'package:selfbox/core/theme/app_glass_theme.dart';
import 'package:selfbox/features/chat/domain/models/message.dart';
import 'package:selfbox/features/chat/presentation/widgets/message_bubble.dart';
import 'package:selfbox/features/chat/presentation/widgets/message_image_stack.dart';

void main() {
  setUpAll(initializeDateFormatting);
  for (final author in MessageAuthor.values) {
    testWidgets('$author keeps the timestamp inside the bubble', (
      tester,
    ) async {
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
      expect(surface.contains(time.topLeft), isTrue);
      expect(surface.contains(time.bottomRight), isTrue);
      expect(
        time.top,
        greaterThan(
          tester.getBottomLeft(find.text('Hello', findRichText: true)).dy,
        ),
      );
    });
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
      expect(tester.getSize(stack).width, lessThanOrEqualTo(240));
      expect(tester.getSize(stack).height, lessThanOrEqualTo(220));
      await tester.tap(stack);
      expect(opened, images.first);
      expect(tester.takeException(), isNull);
    });
  }
}
