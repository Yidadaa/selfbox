import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:selfbox/core/router/app_router.dart';
import 'package:selfbox/core/router/not_found_page.dart';
import 'package:selfbox/core/router/shell_scope.dart';
import 'package:selfbox/core/testing/app_widget_tester.dart';
import 'package:selfbox/core/theme/app_spacing.dart';
import 'package:selfbox/features/chat/presentation/pages/chat_page.dart';
import 'package:selfbox/features/memory/presentation/pages/memory_page.dart';
import 'package:selfbox/features/settings/presentation/pages/me_page.dart';
import 'package:selfbox/gen/i18n/strings.g.dart';

// GlassTabBar paints each label in both a selected and an unselected layer.
Finder _tab(String label) => find
    .descendant(of: find.byType(GlassTabBar), matching: find.text(label))
    .first;

void main() {
  group('appRouter', () {
    testWidgets('starts on the chat tab', (tester) async {
      final container = await tester.pumpApp();

      expect(find.byType(ChatPage), findsOneWidget);
      expect(find.byType(GlassTabBar), findsOneWidget);
      expect(container.read(appRouterProvider).state.matchedLocation, '/chat');
    });

    testWidgets('switches branches from the tab bar', (tester) async {
      final container = await tester.pumpApp();
      final router = container.read(appRouterProvider);

      await tester.tap(_tab(t.tabs.memory));
      await tester.pumpAndSettle();
      expect(router.state.matchedLocation, '/memory');
      expect(find.byType(MemoryPage), findsOneWidget);

      await tester.tap(_tab(t.tabs.me));
      await tester.pumpAndSettle();
      expect(router.state.matchedLocation, '/me');
      expect(find.byType(MePage), findsOneWidget);

      await tester.tap(_tab(t.tabs.chat));
      await tester.pumpAndSettle();
      expect(router.state.matchedLocation, '/chat');
    });

    for (final location in ['/memory', '/me']) {
      testWidgets('deep links straight into $location', (tester) async {
        final container = await tester.pumpApp();
        container.read(appRouterProvider).go(location);
        await tester.pumpAndSettle();

        expect(
          container.read(appRouterProvider).state.matchedLocation,
          location,
        );
      });
    }

    testWidgets('redirects the bare root to chat', (tester) async {
      final container = await tester.pumpApp();
      container.read(appRouterProvider).go('/');
      await tester.pumpAndSettle();

      expect(container.read(appRouterProvider).state.matchedLocation, '/chat');
    });

    testWidgets('tab pages learn the tab bar height through ShellScope', (
      tester,
    ) async {
      await tester.pumpApp();

      final context = tester.element(find.byType(ChatPage));
      final barHeight = tester.getSize(find.byType(GlassTabBar)).height;
      expect(
        ShellScope.bottomInsetOf(context),
        greaterThanOrEqualTo(barHeight),
      );
    });

    testWidgets('renders the 404 page for unknown locations', (tester) async {
      final container = await tester.pumpApp();

      container.read(appRouterProvider).go('/does-not-exist');
      await tester.pumpAndSettle();

      expect(find.byType(NotFoundPage), findsOneWidget);
      expect(find.text(t.notFound.title), findsOneWidget);
    });

    testWidgets('404 back button meets the touch target and returns to chat', (
      tester,
    ) async {
      final container = await tester.pumpApp();
      container.read(appRouterProvider).go('/does-not-exist');
      await tester.pumpAndSettle();

      final button = find.byType(GlassButton);
      final size = tester.getSize(button);
      expect(size.height, greaterThanOrEqualTo(AppSizes.minTouchTarget));
      expect(size.width, greaterThanOrEqualTo(AppSizes.minTouchTarget));

      await tester.tap(button);
      await tester.pumpAndSettle();

      expect(find.byType(ChatPage), findsOneWidget);
      expect(tester.takeException(), isNull);
      expect(find.byType(Scaffold), findsNothing);
    });
  });
}
