import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:selfbox/core/router/app_dock_tabs.dart';
import 'package:selfbox/core/theme/app_effects.dart';
import 'package:selfbox/core/widgets/ai_composer_glow.dart';
import 'package:selfbox/features/chat/presentation/providers/composer_controller.dart';
import 'package:selfbox/features/chat/presentation/widgets/chat_composer_attachment.dart';
import 'package:selfbox/features/chat/presentation/widgets/chat_composer_controls.dart';
import 'package:selfbox/features/settings/domain/models/app_preferences.dart';
import 'package:selfbox/features/settings/presentation/providers/app_preferences_controller.dart';
import 'package:selfbox/gen/i18n/strings.g.dart';

import '../../../../support/app_widget_tester.dart';

Finder get _inputGlass => find.descendant(
  of: find.byKey(const ValueKey('chat-input')),
  matching: find.byType(GlassContainer),
);

void main() {
  testWidgets('AI glow has no independent image blur pass', (tester) async {
    final container = await tester.pumpApp();
    container.read(composerControllerProvider.notifier).toggleAiMode();
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byType(AiComposerGlow),
        matching: find.byType(ImageFiltered),
      ),
      findsNothing,
    );
  });

  testWidgets('keyboard frames keep input glass configuration stable', (
    tester,
  ) async {
    await tester.pumpApp(
      initialPreferences: const AppPreferences(
        renderQuality: AppRenderQuality.premium,
      ),
    );
    await tester.tap(find.byType(EditableText));
    tester.view.viewInsets = const FakeViewPadding(bottom: 900);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 40));
    final glass = tester.widget<GlassContainer>(_inputGlass);
    for (var frame = 0; frame < 8; frame++) {
      await tester.pump(const Duration(milliseconds: 16));
      expect(tester.widget<GlassContainer>(_inputGlass), same(glass));
      final externalGlass = find.descendant(
        of: find.byWidgetPredicate(
          (w) => w is ChatComposerAttachment && w.external,
        ),
        matching: find.byType(GlassContainer),
      );
      expect(externalGlass, findsOneWidget);
      expect(
        tester.widget<GlassContainer>(externalGlass).quality,
        GlassQuality.standard,
      );
      expect(
        find.ancestor(of: externalGlass, matching: find.byType(Opacity)),
        findsNothing,
      );
    }
  });

  testWidgets(
    'typing and composing do not rebuild send control or single-line field',
    (tester) async {
      await tester.pumpApp();
      await tester.enterText(find.byType(EditableText), 'a');
      await tester.pumpAndSettle();
      final send = tester.widget<ChatSendButton>(find.byType(ChatSendButton));
      final field = tester.widget<CupertinoTextField>(
        find.byType(CupertinoTextField),
      );
      for (final text in ['ab', 'abc', '中文', '👋']) {
        tester.testTextInput.updateEditingValue(
          TextEditingValue(
            text: text,
            selection: TextSelection.collapsed(offset: text.length),
            composing: TextRange(start: 0, end: text.length),
          ),
        );
        await tester.pump();
        expect(
          tester.widget<ChatSendButton>(find.byType(ChatSendButton)),
          same(send),
        );
        expect(
          tester.widget<CupertinoTextField>(find.byType(CupertinoTextField)),
          same(field),
        );
      }
    },
  );

  for (final quality in AppRenderQuality.values) {
    testWidgets('all tab dock backgrounds cap $quality at standard', (
      tester,
    ) async {
      await tester.pumpApp(
        initialPreferences: AppPreferences(renderQuality: quality),
      );
      for (final label in [t.tabs.memory, t.tabs.me, t.tabs.chat]) {
        await tester.tap(find.text(label));
        await tester.pumpAndSettle();
        if (quality == AppRenderQuality.minimal) {
          expect(
            find.byKey(
              ValueKey(
                label == t.tabs.chat
                    ? 'composer-solid-background'
                    : 'tab-solid-background',
              ),
            ),
            findsOneWidget,
          );
          final borderSurface = tester.widget<DecoratedBox>(
            find.byKey(
              ValueKey(
                label == t.tabs.chat
                    ? 'ai-composer-outline'
                    : 'tab-solid-background',
              ),
            ),
          );
          final shape =
              (borderSurface.decoration as ShapeDecoration).shape
                  as OutlinedBorder;
          expect(shape.side.width, 0.75);
          expect(shape.side.color.a, inExclusiveRange(0, 0.15));
        } else {
          final surface = tester.widget<GlassContainer>(
            find
                .ancestor(
                  of: find.byType(AppDockTabs),
                  matching: find.byType(GlassContainer),
                )
                .first,
          );
          expect(surface.quality, GlassQuality.standard);
        }
        expect(
          find.byKey(const ValueKey('app-dock-repaint-boundary')),
          findsOneWidget,
        );
      }
    });
  }

  for (final brightness in Brightness.values) {
    testWidgets(
      'minimal surfaces and AI glow preserve editing in $brightness',
      (tester) async {
        tester.platformDispatcher.platformBrightnessTestValue = brightness;
        addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
        final container = await tester.pumpApp();
        await tester.enterText(find.byType(EditableText), 'Keep this draft');
        final before = tester.widget<EditableText>(find.byType(EditableText));
        before.controller.selection = const TextSelection(
          baseOffset: 2,
          extentOffset: 6,
        );
        final preferences = container.read(
          appPreferencesControllerProvider.notifier,
        );
        await preferences.setRenderQuality(AppRenderQuality.minimal);
        await tester.pumpAndSettle();
        expect(_inputGlass, findsNothing);
        final surface = tester.widget<DecoratedBox>(
          find.byKey(const ValueKey('composer-solid-background')),
        );
        final decoration = surface.decoration as ShapeDecoration;
        expect(decoration.color?.a, 1);
        expect(
          decoration.color,
          AppEffects.solidSurface(tester.element(find.byType(AiComposerGlow))),
        );
        expect(decoration.gradient, isNull);
        final outline =
            tester
                    .widget<DecoratedBox>(
                      find.byKey(const ValueKey('ai-composer-outline')),
                    )
                    .decoration
                as ShapeDecoration;
        expect((outline.shape as OutlinedBorder).side.width, 0.75);
        expect(
          (outline.shape as OutlinedBorder).side.color.a,
          inExclusiveRange(0, 0.15),
        );
        container.read(composerControllerProvider.notifier).toggleAiMode();
        await tester.pumpAndSettle();
        final glow = find.descendant(
          of: find.byType(AiComposerGlow),
          matching: find.byType(CustomPaint),
        );
        expect(glow, findsWidgets);
        final aiOutline =
            tester
                    .widget<DecoratedBox>(
                      find.byKey(const ValueKey('ai-composer-outline')),
                    )
                    .decoration
                as ShapeDecoration;
        expect(
          (aiOutline.shape as OutlinedBorder).side,
          (outline.shape as OutlinedBorder).side,
        );
        final after = tester.widget<EditableText>(find.byType(EditableText));
        expect(after.controller, same(before.controller));
        expect(after.focusNode.hasFocus, isTrue);
        expect(
          after.controller.selection,
          const TextSelection(baseOffset: 2, extentOffset: 6),
        );
        expect(after.controller.text, 'Keep this draft');
        await preferences.setRenderQuality(AppRenderQuality.standard);
        await tester.pumpAndSettle();
        expect(_inputGlass, findsOneWidget);
        expect(
          tester
              .widget<EditableText>(find.byType(EditableText))
              .focusNode
              .hasFocus,
          isTrue,
        );
      },
    );
  }
}
