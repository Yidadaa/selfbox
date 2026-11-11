import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:selfbox/core/router/app_router.dart';
import 'package:selfbox/core/router/not_found_page.dart';
import 'package:selfbox/core/testing/app_widget_tester.dart';
import 'package:selfbox/core/theme/app_spacing.dart';
import 'package:selfbox/features/home/presentation/pages/home_page.dart';
import 'package:selfbox/gen/i18n/strings.g.dart';

void main() {
  group('appRouter', () {
    testWidgets('starts on the home page', (tester) async {
      await tester.pumpApp();

      expect(find.byType(HomePage), findsOneWidget);
      expect(find.text(t.home.welcome), findsOneWidget);
    });

    testWidgets('renders the 404 page for unknown locations', (tester) async {
      final container = await tester.pumpApp();

      container.read(appRouterProvider).go('/does-not-exist');
      await tester.pumpAndSettle();

      expect(find.byType(NotFoundPage), findsOneWidget);
      expect(find.text(t.notFound.title), findsOneWidget);
    });

    testWidgets('404 back button meets the touch target and returns home', (
      tester,
    ) async {
      final container = await tester.pumpApp();
      container.read(appRouterProvider).go('/does-not-exist');
      await tester.pumpAndSettle();

      final button = find.byType(GlassButton);
      expect(
        tester.getSize(button).height,
        greaterThanOrEqualTo(AppSizes.minTouchTarget),
      );
      expect(
        tester.getSize(button).width,
        greaterThanOrEqualTo(AppSizes.minTouchTarget),
      );

      await tester.tap(button);
      await tester.pumpAndSettle();

      expect(find.byType(HomePage), findsOneWidget);
      expect(container.read(appRouterProvider).state.matchedLocation, '/');
    });
  });
}
