import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_smooth_markdown/flutter_smooth_markdown.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:selfbox/core/theme/message_tokens.dart';
import 'package:selfbox/core/theme/sdk_material.dart';
import 'package:selfbox/core/widgets/app_action_popover.dart';
import 'package:selfbox/core/widgets/app_confirm_dialog.dart';
import 'package:selfbox/features/chat/domain/models/message.dart';
import 'package:selfbox/gen/i18n/strings.g.dart';

import '../../../../support/app_widget_tester.dart';
import '../../../../support/fake_message_repository.dart';

void main() {
  setUpAll(initializeDateFormatting);
  for (final brightness in Brightness.values) {
    for (final author in MessageAuthor.values) {
      testWidgets(
        '$author opens actions before selecting a word in $brightness',
        (tester) async {
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
          tester.platformDispatcher.platformBrightnessTestValue = brightness;
          addTearDown(
            tester.platformDispatcher.clearPlatformBrightnessTestValue,
          );
          await tester.pumpApp(
            messages: FakeMessageRepository(
              seed: [
                Message(
                  id: 1,
                  createdAt: kTestNow,
                  author: author,
                  text: 'alpha beta gamma',
                ),
              ],
            ),
          );
          if (author == MessageAuthor.ai) {
            await tester.tap(find.bySemanticsLabel(t.chat.aiMode));
            await tester.pump();
            await tester.pump(const Duration(milliseconds: 600));
          }
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
          final wordPosition = paragraph.localToGlobal(word.center);
          await tester.longPressAt(wordPosition);
          await tester.pump(const Duration(milliseconds: 600));
          expect(find.byType(AppActionPopover), findsOneWidget);

          expect(find.text(t.common.selectText), findsOneWidget);
          expect(find.text(t.common.selectAll), findsNothing);
          await tester.tap(find.text(t.common.selectText));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 600));
          expect(find.byType(SmoothSelectionRegion), findsOneWidget);
          final region = tester.widget<SmoothSelectionRegion>(
            find.byType(SmoothSelectionRegion),
          );
          final selectedText = tester.widget<RichText>(rich);
          final selectionColor = selectedText.selectionColor;
          expect(selectionColor, MessageTokens.selectionColor(brightness));
          expect(selectionColor?.r, selectionColor?.g);
          expect(selectionColor?.a, inExclusiveRange(0, 0.4));
          expect(region.controller?.isAttached, isTrue);
          expect(region.controller?.contextMenuButtonItems, isNotEmpty);
          region.controller?.contextMenuButtonItems
              .firstWhere((item) => item.type == ContextMenuButtonType.copy)
              .onPressed
              ?.call();
          expect(copied, 'beta');
          await tester.longPressAt(wordPosition);
          await tester.pump(const Duration(milliseconds: 600));
          expect(find.byType(AppActionPopover), findsOneWidget);
          expect(find.text(t.common.selectAll), findsOneWidget);
          await tester.tap(find.text(t.common.copy));
          await tester.pump(const Duration(milliseconds: 600));
          expect(copied, 'beta');
          expect(
            find.widgetWithText(GlassToast, t.common.copied),
            findsOneWidget,
          );
          await tester.pump(const Duration(seconds: 4));
          expect(find.byType(AppActionPopover), findsNothing);
          await tester.longPressAt(wordPosition);
          await tester.pump(const Duration(milliseconds: 600));
          expect(find.text(t.common.selectText), findsOneWidget);
          await tester.tap(find.text(t.common.selectText));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 600));
          await tester.longPressAt(wordPosition);
          await tester.pump(const Duration(milliseconds: 600));
          await tester.tap(find.text(t.common.selectAll));
          await tester.pump(const Duration(milliseconds: 600));
          await tester.tap(find.text(t.common.copy));
          await tester.pump(const Duration(milliseconds: 600));
          expect(copied, 'alpha beta gamma');
          expect(
            find.widgetWithText(GlassToast, t.common.copied),
            findsOneWidget,
          );
          await tester.pump(const Duration(seconds: 4));
          await tester.longPressAt(wordPosition);
          await tester.pumpAndSettle();
          await tester.tap(find.text(t.common.selectText));
          await tester.pumpAndSettle();
          await tester.longPressAt(wordPosition);
          await tester.pumpAndSettle();
          await tester.tap(find.text(t.common.delete));
          await tester.pumpAndSettle();
          expect(find.byType(AppConfirmDialog), findsOneWidget);
          expect(rich, findsOneWidget);
          await tester.tap(find.text(t.common.cancel));
          await tester.pumpAndSettle();
          expect(rich, findsOneWidget);
          expect(find.byType(AppActionPopover), findsNothing);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}
