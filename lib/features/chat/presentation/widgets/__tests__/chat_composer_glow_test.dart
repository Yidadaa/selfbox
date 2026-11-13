import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:selfbox/core/router/app_dock_tabs.dart';
import 'package:selfbox/core/testing/app_widget_tester.dart';
import 'package:selfbox/core/theme/app_glass_theme.dart';
import 'package:selfbox/core/theme/app_spacing.dart';
import 'package:selfbox/core/widgets/ai_composer_glow.dart';
import 'package:selfbox/features/chat/presentation/providers/composer_controller.dart';
import 'package:selfbox/features/chat/presentation/widgets/chat_composer_controls.dart';
import 'package:selfbox/gen/i18n/strings.g.dart';

class _AttachedDraft extends ComposerController {
  @override
  ComposerState build() =>
      const ComposerState(attachments: ['../unavailable.png']);
}

void main() {
  for (final brightness in Brightness.values) {
    testWidgets('AI glow covers only input and tabs across keyboard states '
        'in ${brightness.name}', (tester) async {
      tester.platformDispatcher.platformBrightnessTestValue = brightness;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
      await tester.pumpApp(
        overrides: [
          composerControllerProvider.overrideWith(_AttachedDraft.new),
        ],
      );
      final glow = find.byType(AiComposerGlow);
      final input = find.byKey(const ValueKey('chat-input'));
      final closedRect = tester.getRect(input);
      await tester.tap(find.bySemanticsLabel(t.chat.aiMode));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      expect(tester.getRect(glow), closedRect);
      final outline = find.byKey(const ValueKey('ai-composer-outline'));
      final inputSurface = tester.widget<GlassContainer>(
        find.descendant(of: input, matching: find.byType(GlassContainer)),
      );
      if (brightness == Brightness.light) {
        expect(tester.getRect(outline), closedRect);
        final decoration =
            tester.widget<DecoratedBox>(outline).decoration as ShapeDecoration;
        expect(
          decoration.shape,
          inputSurface.shape.copyWith(
            side: BorderSide(
              color: AppGlassTheme.of(brightness).composerAiOutline,
            ),
          ),
        );
      } else {
        expect(outline, findsNothing);
      }
      expect(
        find.descendant(of: glow, matching: find.byType(AppDockTabs)),
        findsOneWidget,
      );
      expect(
        find.descendant(of: glow, matching: find.byType(ChatAiToggle)),
        findsNothing,
      );
      expect(
        find.descendant(of: glow, matching: find.byType(ChatAttachmentStrip)),
        findsNothing,
      );
      expect(
        tester.getRect(glow).top,
        greaterThan(tester.getRect(find.byType(ChatAiToggle)).bottom),
      );

      final editable = find.byType(EditableText);
      await tester.enterText(editable, 'one\ntwo\nthree');
      final field = tester.widget<EditableText>(editable);
      tester.view.viewInsets = const FakeViewPadding(bottom: 900);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      expect(tester.getRect(glow), tester.getRect(input));
      if (brightness == Brightness.light) {
        expect(tester.getRect(outline), tester.getRect(input));
      }
      expect(tester.getRect(glow).height, lessThan(closedRect.height));
      expect(
        find.descendant(of: glow, matching: find.byType(AppDockTabs)),
        findsNothing,
      );
      expect(
        find.descendant(of: glow, matching: find.byType(ChatAttachButton)),
        findsNothing,
      );
      expect(
        tester.getRect(glow).left,
        greaterThan(tester.getRect(find.byType(ChatAttachButton)).right),
      );
      expect(
        tester.getRect(glow).bottom,
        closeTo(kPhoneViewport.height - 300 - AppSpacing.xs, 0.01),
      );

      field.focusNode.unfocus();
      for (final inset in [900.0, 450.0, 0.0]) {
        tester.view.viewInsets = FakeViewPadding(bottom: inset);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 600));
        expect(tester.getRect(glow), tester.getRect(input));
        expect(
          find.descendant(of: glow, matching: find.byType(AppDockTabs)),
          findsOneWidget,
        );
      }
      final after = tester.widget<EditableText>(editable);
      expect(after.controller, same(field.controller));
      expect(after.controller.text, 'one\ntwo\nthree');
      expect(tester.takeException(), isNull);
    });
  }
}
