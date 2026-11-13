import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:selfbox/core/testing/app_widget_tester.dart';
import 'package:selfbox/core/widgets/app_action_popover.dart';
import 'package:selfbox/features/chat/domain/models/message.dart';
import 'package:selfbox/features/chat/presentation/widgets/message_bubble.dart';
import 'package:selfbox/gen/i18n/strings.g.dart';

void main() {
  setUpAll(initializeDateFormatting);
  for (final author in MessageAuthor.values) {
    testWidgets('$author long press copies the selected word', (tester) async {
      String? copied;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            copied =
                (call.arguments as Map<Object?, Object?>)['text'] as String;
          }
          return null;
        },
      );
      addTearDown(() {
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        );
      });
      await tester.pumpPage(
        Center(
          child: MessageBubble(
            message: Message(
              id: 1,
              createdAt: kTestNow,
              author: author,
              text: 'alpha beta gamma',
            ),
            resolveImage: (_) => null,
          ),
        ),
      );
      final rich = find.byWidgetPredicate(
        (widget) =>
            widget is RichText &&
            widget.text.toPlainText().contains('alpha beta gamma'),
      );
      final paragraph = tester.renderObject<RenderParagraph>(rich);
      final word = paragraph
          .getBoxesForSelection(
            const TextSelection(baseOffset: 6, extentOffset: 10),
          )
          .first
          .toRect();
      await tester.longPressAt(paragraph.localToGlobal(word.center));
      await tester.pumpAndSettle();
      expect(find.byType(AppActionPopover), findsOneWidget);
      expect(find.byType(Dialog), findsNothing);
      await tester.tap(find.text(t.common.copy));
      await tester.pumpAndSettle();
      expect(copied, 'beta');
      expect(find.byType(AppActionPopover), findsNothing);
      await tester.longPressAt(paragraph.localToGlobal(word.center));
      await tester.pumpAndSettle();
      await tester.tap(find.text(t.common.selectAll));
      await tester.pumpAndSettle();
      await tester.tap(find.text(t.common.copy));
      await tester.pumpAndSettle();
      expect(copied, 'alpha beta gamma');
      expect(tester.takeException(), isNull);
    });
  }
}
