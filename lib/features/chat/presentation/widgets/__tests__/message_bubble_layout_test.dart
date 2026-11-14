import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:selfbox/core/testing/app_widget_tester.dart';
import 'package:selfbox/core/theme/message_tokens.dart';
import 'package:selfbox/features/chat/domain/models/message.dart';
import 'package:selfbox/features/chat/presentation/widgets/message_bubble.dart';

void main() {
  setUpAll(initializeDateFormatting);
  for (final (width, scale) in [(280.0, 1.0), (390.0, 1.5)]) {
    testWidgets('AI bubbles size to text within $width/$scale bounds', (
      tester,
    ) async {
      final text = ValueNotifier('Hello');
      addTearDown(text.dispose);
      await tester.pumpPage(
        SingleChildScrollView(
          child: ValueListenableBuilder(
            valueListenable: text,
            builder: (_, value, _) => MessageBubble(
              message: Message(
                id: 1,
                createdAt: kTestNow,
                author: MessageAuthor.ai,
                text: value,
              ),
              resolveImage: (_) => null,
            ),
          ),
        ),
      );
      tester.view.physicalSize = Size(width * 3, 844 * 3);
      tester.platformDispatcher.textScaleFactorTestValue = scale;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      for (final value in [
        'Hello',
        '**Hi**',
        '你好',
        '`code`',
        '[link](https://example.com)',
      ]) {
        text.value = value;
        await tester.pumpAndSettle();
        final surface = tester.getRect(
          find.byKey(const ValueKey('message-surface')),
        );
        expect(surface.width, lessThan(width * MessageTokens.widthFactor - 1));
        expect(surface.left, greaterThanOrEqualTo(0));
        expect(tester.takeException(), isNull);
      }
      for (final value in [
        List.filled(30, 'long reply with wrapping').join(' '),
        '```dart\nfinal value = 42;\n```',
        '| Name | Value |\n| --- | --- |\n| a | b |',
        r'$$ x^2 + y^2 = 1 $$',
        '> A quotation',
      ]) {
        text.value = value;
        await tester.pumpAndSettle();
        expect(
          tester.getSize(find.byKey(const ValueKey('message-surface'))).width,
          lessThanOrEqualTo(width * MessageTokens.widthFactor),
        );
        expect(tester.takeException(), isNull);
      }
    });
  }
}
