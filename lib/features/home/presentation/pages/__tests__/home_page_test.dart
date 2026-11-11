import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:selfbox/core/testing/app_widget_tester.dart';
import 'package:selfbox/core/theme/app_spacing.dart';
import 'package:selfbox/features/home/presentation/pages/home_page.dart';
import 'package:selfbox/gen/i18n/strings.g.dart';

void main() {
  group('HomePage', () {
    for (final locale in AppLocale.values) {
      testWidgets('renders the welcome card in ${locale.languageTag}', (
        tester,
      ) async {
        await tester.pumpPage(const HomePage(), locale: locale);

        final strings = locale.buildSync();
        expect(find.text(strings.home.title), findsOneWidget);
        expect(find.text(strings.home.welcome), findsOneWidget);
        expect(find.text(strings.home.subtitle), findsOneWidget);
        expect(find.byType(SvgPicture), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('places content inside a glass card under a glass app bar', (
      tester,
    ) async {
      await tester.pumpPage(const HomePage());

      expect(find.byType(GlassScaffold), findsOneWidget);
      expect(find.byType(GlassAppBar), findsOneWidget);
      expect(
        find.ancestor(
          of: find.text(t.home.welcome),
          matching: find.byType(GlassContainer),
        ),
        findsOneWidget,
      );
    });

    test('AppSizes.appBarHeight tracks the GlassAppBar default height', () {
      expect(const GlassAppBar().preferredSize.height, AppSizes.appBarHeight);
    });

    testWidgets('welcome card clears the top safe area and app bar', (
      tester,
    ) async {
      await tester.pumpPage(const HomePage());

      final appBarBottom = tester.getBottomLeft(find.byType(GlassAppBar)).dy;
      final cardTop = tester.getTopLeft(find.byType(GlassContainer)).dy;
      expect(cardTop, greaterThanOrEqualTo(appBarBottom));
    });
  });
}
