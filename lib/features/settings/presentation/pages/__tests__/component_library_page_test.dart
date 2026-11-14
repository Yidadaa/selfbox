import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:selfbox/core/router/app_router.dart';
import 'package:selfbox/core/testing/app_widget_tester.dart';
import 'package:selfbox/core/widgets/ai_composer_glow.dart';
import 'package:selfbox/core/widgets/app_action_button.dart';
import 'package:selfbox/core/widgets/app_action_popover.dart';
import 'package:selfbox/core/widgets/app_confirm_dialog.dart';
import 'package:selfbox/core/widgets/app_modal_surface.dart';
import 'package:selfbox/core/widgets/app_page_button.dart';
import 'package:selfbox/features/settings/domain/models/app_preferences.dart';
import 'package:selfbox/gen/i18n/strings.g.dart';

void main() {
  testWidgets('component library previews the real animated composer glow', (
    tester,
  ) async {
    final container = await tester.pumpApp();
    container.read(appRouterProvider).go('/me/components');
    await tester.pumpAndSettle();
    final toggle = find.byKey(const ValueKey('component-glow-toggle'));
    await tester.scrollUntilVisible(toggle, 250);
    expect(
      tester.widget<AiComposerGlow>(find.byType(AiComposerGlow)).active,
      isFalse,
    );
    await tester.tap(toggle);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));
    expect(
      tester.widget<AiComposerGlow>(find.byType(AiComposerGlow)).active,
      isTrue,
    );
    expect(find.text(t.chat.aiStandby), findsOneWidget);
    await tester.tap(toggle);
    await tester.pumpAndSettle();
    expect(
      tester.widget<AiComposerGlow>(find.byType(AiComposerGlow)).active,
      isFalse,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Me separates developer entries and opens component library', (
    tester,
  ) async {
    final container = await tester.pumpApp(
      initialPreferences: const AppPreferences(developerToolsUnlocked: true),
    );
    container.read(appRouterProvider).go('/me');
    await tester.pumpAndSettle();

    expect(find.text(t.me.logs), findsOneWidget);
    expect(find.text(t.me.componentLibrary), findsOneWidget);
    expect(find.text(t.me.developer), findsOneWidget);

    await tester.tap(find.text(t.me.componentLibrary));
    await tester.pumpAndSettle();
    expect(find.text(t.me.componentLibrary), findsOneWidget);
    expect(find.byType(AppActionButton), findsNWidgets(3));
    expect(find.byType(AppActionIconButton), findsNWidgets(3));
    expect(find.text(t.common.save), findsOneWidget);
    expect(find.text(t.common.cancel), findsOneWidget);
    expect(find.text(t.common.delete), findsOneWidget);

    final preview = find.byKey(const ValueKey('component-popover-preview'));
    await tester.scrollUntilVisible(preview, 150);
    expect(find.byType(AppPageButton), findsNWidgets(2));
    await tester.tap(preview);
    await tester.pumpAndSettle();
    expect(find.byType(AppActionPopover), findsOneWidget);
    await tester.tapAt(const Offset(24, 150));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text(t.me.componentLibraryDialog),
      100,
    );
    await tester.tap(find.text(t.me.componentLibraryDialog));
    await tester.pumpAndSettle();
    expect(find.byType(AppActionDialog), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(Dialog),
        matching: find.byType(AppActionButton),
      ),
      findsNWidgets(3),
    );
    await tester.tap(
      find.descendant(
        of: find.byType(Dialog),
        matching: find.text(t.common.cancel),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text(t.me.componentLibrarySheet), 100);
    await tester.tap(find.text(t.me.componentLibrarySheet));
    await tester.pumpAndSettle();
    expect(find.byType(AppModalSurface), findsOneWidget);
    expect(
      find.byKey(const ValueKey('component-sheet-picker')),
      findsOneWidget,
    );
  });
}
