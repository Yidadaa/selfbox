import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:selfbox/core/testing/app_widget_tester.dart';
import 'package:selfbox/core/widgets/app_action_button.dart';
import 'package:selfbox/core/widgets/app_artwork.dart';
import 'package:selfbox/core/widgets/empty_state.dart';

void main() {
  for (final brightness in Brightness.values) {
    testWidgets(
      'illustrated states adapt to short screens in ${brightness.name}',
      (tester) async {
        var retries = 0;
        await tester.pumpPage(
          EmptyState(
            label: 'Unable to load',
            illustration: BrandArt.error,
            action: AppActionButton(label: 'Retry', onPressed: () => retries++),
          ),
          brightness: brightness,
        );
        tester.view.physicalSize = const Size(280 * 3, 300 * 3);
        tester.platformDispatcher.textScaleFactorTestValue = 2;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        await tester.pumpAndSettle();
        expect(find.byType(AppArtwork), findsOneWidget);
        expect(
          tester.getSize(find.byType(AppArtwork)).width,
          lessThanOrEqualTo(120),
        );
        await tester.ensureVisible(find.text('Retry'));
        await tester.tap(find.text('Retry'));
        expect(retries, 1);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'every artwork preserves its bounds and aspect in ${brightness.name}',
      (tester) async {
        for (final art in BrandArt.values) {
          await tester.pumpPage(
            Center(child: AppArtwork(art, size: 72)),
            brightness: brightness,
          );
          expect(tester.getSize(find.byType(AppArtwork)), const Size(72, 72));
          final image = tester.widget<Image>(find.byType(Image));
          expect(image.fit, BoxFit.contain);
          expect(image.excludeFromSemantics, isTrue);
          expect(tester.takeException(), isNull);
        }
      },
    );
  }
}
