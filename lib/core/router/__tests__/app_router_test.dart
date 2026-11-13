import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:selfbox/core/logger/talker_provider.dart';
import 'package:selfbox/core/router/app_dock_tabs.dart';
import 'package:selfbox/core/router/app_router.dart';
import 'package:selfbox/core/router/app_routes.dart';
import 'package:selfbox/core/router/not_found_page.dart';
import 'package:selfbox/core/router/shell_scope.dart';
import 'package:selfbox/core/testing/app_widget_tester.dart';
import 'package:selfbox/core/theme/app_glass_theme.dart';
import 'package:selfbox/core/theme/app_spacing.dart';
import 'package:selfbox/features/chat/presentation/pages/chat_page.dart';
import 'package:selfbox/features/chat/presentation/widgets/chat_composer.dart';
import 'package:selfbox/features/chat/presentation/widgets/message_bubble.dart';
import 'package:selfbox/features/memory/presentation/pages/memory_page.dart';
import 'package:selfbox/features/settings/presentation/pages/me_page.dart';
import 'package:selfbox/gen/i18n/strings.g.dart';
import 'package:talker_flutter/talker_flutter.dart';

Finder _tab(String label) => find
    .descendant(
      of: find.byWidgetPredicate((w) => w is AppDockTabs),
      matching: find.text(label),
    )
    .first;

void main() {
  group('appRouter', () {
    testWidgets('starts on the chat tab', (tester) async {
      final container = await tester.pumpApp();

      expect(find.byType(ChatPage), findsOneWidget);
      expect(find.byType(GlassScaffold), findsOneWidget);
      expect(find.byType(AppDockTabs), findsOneWidget);
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

    for (final location in [
      const MemoryFileRoute(path: 'missing.md').location,
      const ProfileRoute().location,
      const GeneralRoute().location,
      const StorageRoute().location,
      const AiProvidersRoute().location,
      const AboutRoute().location,
      const TalkerRoute().location,
      const ProviderRoute().location,
      const ModelRoute(provider: 'missing', model: 'missing').location,
      const ImageViewerRoute(path: 'missing.jpg').location,
    ]) {
      testWidgets('secondary page $location covers the tab bar', (
        tester,
      ) async {
        final container = await tester.pumpApp();
        container.read(appRouterProvider).go(location);
        await tester.pumpAndSettle();
        expect(
          container.read(appRouterProvider).state.matchedLocation,
          location.split('?').first,
        );
        expect(find.byType(AppDockTabs), findsNothing);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('Me opens the Talker log screen without tabs', (tester) async {
      final container = await tester.pumpApp();
      await tester.tap(_tab(t.tabs.me));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<GlassGroupedSection>(find.byType(GlassGroupedSection).first)
            .quality,
        GlassQuality.standard,
      );
      await tester.tap(find.text(t.me.logs));
      await tester.pumpAndSettle();
      final screen = tester.widget<TalkerScreen>(find.byType(TalkerScreen));
      expect(screen.talker, same(container.read(talkerProvider)));
      expect(find.byType(AppDockTabs), findsNothing);
    });

    for (final location in ['/memory', '/me']) {
      for (final brightness in Brightness.values) {
        testWidgets(
          '$location tab dock uses themed chrome in ${brightness.name}',
          (tester) async {
            tester.platformDispatcher.platformBrightnessTestValue = brightness;
            addTearDown(
              tester.platformDispatcher.clearPlatformBrightnessTestValue,
            );
            final container = await tester.pumpApp();
            container.read(appRouterProvider).go(location);
            await tester.pumpAndSettle();
            final tabs = tester.getRect(find.byType(AppDockTabs));
            final dock = tester.widget<GlassContainer>(
              find
                  .ancestor(
                    of: find.byType(AppDockTabs),
                    matching: find.byType(GlassContainer),
                  )
                  .first,
            );
            expect(dock.useOwnLayer, isTrue);
            final glass = AppGlassTheme.of(brightness);
            expect(dock.settings?.blur, glass.chromeBlur);
            expect(dock.settings?.glassColor, glass.chromeTint);
            expect(tabs.left, AppSpacing.md);
            expect(tabs.right, kPhoneViewport.width - AppSpacing.md);
            expect(tabs.bottom, kPhoneViewport.height - 34 - AppSpacing.md);
          },
        );
      }
    }

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
      final barHeight = tester.getSize(find.byType(AppDockTabs)).height;
      expect(
        ShellScope.bottomInsetOf(context),
        greaterThanOrEqualTo(barHeight),
      );
    });

    testWidgets(
      'chat timeline keeps its bottom inset on the first return frame',
      (tester) async {
        await tester.pumpApp();
        final timeline = find.descendant(
          of: find.byType(ChatPage),
          matching: find.byType(ListView),
        );
        double bottomPadding() =>
            (tester.widget<ListView>(timeline).padding! as EdgeInsets).bottom;
        final original = bottomPadding();
        final originalBubble = tester.getRect(find.byType(MessageBubble).first);

        await tester.tap(_tab(t.tabs.memory));
        await tester.pumpAndSettle();
        await tester.tap(_tab(t.tabs.chat));
        await tester.pump();
        expect(bottomPadding(), original);
        expect(
          tester.getRect(find.byType(MessageBubble).first),
          originalBubble,
        );
        await tester.pumpAndSettle();
        expect(bottomPadding(), original);
        expect(
          tester.getRect(find.byType(MessageBubble).first),
          originalBubble,
        );
      },
    );

    testWidgets('chat timeline follows a growing composer', (tester) async {
      await tester.pumpApp();
      final context = tester.element(find.byType(ChatPage));
      final originalInset = ShellScope.bottomInsetOf(context);
      final originalDock = tester.getSize(find.byType(ChatComposer)).height;

      await tester.enterText(
        find.byType(EditableText),
        'one\ntwo\nthree\nfour\nfive',
      );
      await tester.pumpAndSettle();

      final grownDock = tester.getSize(find.byType(ChatComposer)).height;
      expect(grownDock, greaterThan(originalDock));
      expect(
        ShellScope.bottomInsetOf(context),
        originalInset + grownDock - originalDock,
      );
    });

    testWidgets('renders the 404 page for unknown locations', (tester) async {
      final container = await tester.pumpApp();

      container.read(appRouterProvider).go('/does-not-exist');
      await tester.pumpAndSettle();

      expect(find.byType(NotFoundPage), findsOneWidget);
      expect(find.text(t.notFound.title), findsOneWidget);
      expect(find.byIcon(Icons.explore_off_rounded), findsNothing);
      expect(
        find.ancestor(
          of: find.text(t.notFound.title),
          matching: find.byType(GlassContainer),
        ),
        findsNothing,
      );
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
