import 'package:flutter_smooth_markdown/flutter_smooth_markdown.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:selfbox/core/router/app_router.dart';
import 'package:selfbox/core/theme/sdk_cupertino.dart';
import 'package:selfbox/core/theme/sdk_material.dart';
import 'package:selfbox/features/memory/presentation/pages/memory_editor_page.dart';
import 'package:selfbox/gen/i18n/strings.g.dart';

import '../../../../support/app_widget_tester.dart';
import '../../../../support/fake_memory_repository.dart';

void main() {
  for (final brightness in Brightness.values) {
    testWidgets('new memory hints match in $brightness', (tester) async {
      tester.platformDispatcher.platformBrightnessTestValue = brightness;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
      final container = await tester.pumpApp(memory: FakeMemoryRepository());
      container.read(appRouterProvider).go('/memory/edit');
      await tester.pumpAndSettle();

      final titleInput = tester.widget<CupertinoTextField>(
        find.descendant(
          of: find.byType(GlassTextField),
          matching: find.byType(CupertinoTextField),
        ),
      );
      final bodyInput = find.descendant(
        of: find.byType(SmoothMarkdownEditor),
        matching: find.byType(TextField),
      );
      final titleColor = titleInput.placeholderStyle?.color;
      final bodyColor = Theme.of(tester.element(bodyInput))
          .inputDecorationTheme
          .hintStyle
          ?.color;
      expect(titleColor, isNotNull);
      expect(bodyColor, titleColor);
      expect(bodyColor?.a, titleColor?.a);
      final bodyHint = find.text(t.memory.contentHint);
      expect(bodyHint, findsOneWidget);
      expect(tester.widget<Text>(bodyHint).style?.color, titleColor);
    });

    testWidgets(
      'editor uses readable text and stays usable with a keyboard in $brightness',
      (tester) async {
        tester.platformDispatcher.platformBrightnessTestValue = brightness;
        addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
        final memory = FakeMemoryRepository(
          seed: {'user.md': '用户尚未设置名字，可以引导用户点击头像设置名字和头像。\n'},
        );
        final container = await tester.pumpApp(
          memory: memory,
          locale: AppLocale.zhCn,
        );
        container.read(appRouterProvider).go('/memory/edit?path=user.md');
        await tester.pumpAndSettle();

        final editor = tester.widget<SmoothMarkdownEditor>(
          find.byType(SmoothMarkdownEditor),
        );
        expect(editor.textStyle?.fontFamily, isNot('monospace'));
        expect(
          editor.textStyle?.color,
          Theme.of(tester.element(find.byType(SmoothMarkdownEditor)))
              .textTheme
              .bodyLarge
              ?.color,
        );

        tester.view.physicalSize = const Size(320 * 3, 844 * 3);
        tester.view.viewInsets = const FakeViewPadding(bottom: 300 * 3);
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
          find.text(t.common.save),
          200,
          scrollable: find
              .descendant(
                of: find.byType(MemoryEditorPage),
                matching: find.byType(Scrollable),
              )
              .first,
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(
          tester.getRect(find.text(t.common.save)).bottom,
          lessThanOrEqualTo(844 - 300),
        );
      },
    );
  }
}
