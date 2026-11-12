import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:selfbox/core/router/shell_scope.dart';
import 'package:selfbox/core/testing/app_widget_tester.dart';
import 'package:selfbox/core/theme/app_glass_theme.dart';
import 'package:selfbox/core/theme/app_spacing.dart';
import 'package:selfbox/core/widgets/app_page_scaffold.dart';
import 'package:selfbox/core/widgets/empty_state.dart';

void main() {
  for (final brightness in Brightness.values) {
    testWidgets('$brightness uses the canvas top color for the edge fade', (
      tester,
    ) async {
      await tester.pumpPage(
        const AppPageScaffold(title: 'Page', body: SizedBox.shrink()),
        brightness: brightness,
      );

      final scaffold = tester.widget<GlassScaffold>(
        find.descendant(
          of: find.byType(AppPageScaffold),
          matching: find.byType(GlassScaffold),
        ),
      );
      expect(
        scaffold.backgroundColor,
        AppGlassTheme.of(brightness).canvasGradient.first,
      );
    });
  }

  group('EmptyState', () {
    testWidgets('shows centered small text without a card or icon', (
      tester,
    ) async {
      await tester.pumpPage(const EmptyState(label: 'Empty'));

      final label = find.text('Empty');
      expect(tester.getCenter(label).dx, closeTo(kPhoneViewport.width / 2, 1));
      expect(tester.getCenter(label).dy, closeTo(kPhoneViewport.height / 2, 1));
      expect(find.byType(Icon), findsNothing);
      expect(
        find.ancestor(of: label, matching: find.byType(GlassContainer)),
        findsNothing,
      );
      expect(
        tester.widget<Text>(label).style?.fontSize,
        Theme.of(tester.element(label)).textTheme.bodySmall?.fontSize,
      );
    });

    testWidgets('keeps an error action below the plain label', (tester) async {
      await tester.pumpPage(
        const EmptyState(label: 'Empty', action: Text('Retry')),
      );

      expect(find.text('Retry'), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('Retry')).dy,
        greaterThan(tester.getBottomLeft(find.text('Empty')).dy),
      );
      expect(
        find.ancestor(
          of: find.text('Empty'),
          matching: find.byType(GlassContainer),
        ),
        findsNothing,
      );
    });
  });

  group('AppPageInsets', () {
    testWidgets('aligns app bar and page content with the chat dock', (
      tester,
    ) async {
      await tester.pumpPage(
        const AppPageScaffold(title: 'Page', body: SizedBox.shrink()),
      );

      final appBar = tester.widget<GlassAppBar>(find.byType(GlassAppBar));
      final insets = AppPageInsets.of(tester.element(find.byType(GlassAppBar)));

      expect(appBar.padding.horizontal, AppInsets.pageHorizontal * 2);
      expect(insets.left, AppInsets.pageHorizontal);
      expect(insets.right, AppInsets.pageHorizontal);
    });

    testWidgets('clears the safe area, app bar and shell tab bar', (
      tester,
    ) async {
      late EdgeInsets insets;
      await tester.pumpPage(
        ShellScope(
          bottomInset: 120,
          child: Builder(
            builder: (context) {
              insets = AppPageInsets.of(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(insets.top, 47 + AppSizes.appBarHeight + AppSpacing.md);
      expect(insets.bottom, 120 + AppSpacing.md);
      expect(insets.left, AppSpacing.md);
    });

    testWidgets('falls back to the home indicator outside the shell', (
      tester,
    ) async {
      late EdgeInsets insets;
      await tester.pumpPage(
        Builder(
          builder: (context) {
            insets = AppPageInsets.of(context);
            return const SizedBox.shrink();
          },
        ),
      );

      expect(insets.bottom, 34 + AppSpacing.md);
    });
  });
}
