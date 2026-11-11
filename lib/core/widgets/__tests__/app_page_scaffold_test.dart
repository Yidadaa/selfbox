import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:selfbox/core/router/shell_scope.dart';
import 'package:selfbox/core/testing/app_widget_tester.dart';
import 'package:selfbox/core/theme/app_spacing.dart';
import 'package:selfbox/core/widgets/app_page_scaffold.dart';
import 'package:selfbox/core/widgets/empty_state.dart';

void main() {
  group('EmptyState', () {
    testWidgets('shows the icon and label inside a glass card', (tester) async {
      await tester.pumpPage(
        const EmptyState(icon: Icons.inbox_outlined, label: 'Empty'),
      );

      expect(find.byIcon(Icons.inbox_outlined), findsOneWidget);
      expect(
        find.ancestor(
          of: find.text('Empty'),
          matching: find.byType(GlassContainer),
        ),
        findsOneWidget,
      );
    });

    testWidgets('places the action outside the glass card', (tester) async {
      await tester.pumpPage(
        const EmptyState(
          icon: Icons.inbox_outlined,
          label: 'Empty',
          action: Text('Retry'),
        ),
      );

      expect(find.text('Retry'), findsOneWidget);
      expect(
        find.ancestor(
          of: find.text('Retry'),
          matching: find.byType(GlassContainer),
        ),
        findsNothing,
      );
    });
  });

  group('AppPageInsets', () {
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
