import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:selfbox/core/router/app_dock_tabs.dart';
import 'package:selfbox/core/testing/app_widget_tester.dart';
import 'package:selfbox/core/widgets/ai_composer_glow.dart';
import 'package:selfbox/features/chat/presentation/providers/composer_controller.dart';
import 'package:selfbox/features/chat/presentation/widgets/chat_composer_attachment.dart';
import 'package:selfbox/features/chat/presentation/widgets/chat_composer_controls.dart';
import 'package:selfbox/features/settings/domain/models/app_preferences.dart';
import 'package:selfbox/gen/i18n/strings.g.dart';

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
        final surface = tester.widget<GlassContainer>(
          find
              .ancestor(
                of: find.byType(AppDockTabs),
                matching: find.byType(GlassContainer),
              )
              .first,
        );
        expect(
          surface.quality,
          quality == AppRenderQuality.minimal
              ? GlassQuality.minimal
              : GlassQuality.standard,
        );
        expect(
          find.byKey(const ValueKey('app-dock-repaint-boundary')),
          findsOneWidget,
        );
      }
    });
  }
}
