import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:selfbox/core/theme/sdk_material.dart';
import 'package:selfbox/features/memory/presentation/pages/memory_editor_page.dart';
import 'package:selfbox/features/settings/domain/models/app_preferences.dart';

void registerTests(
  Future<void> Function(WidgetTester, AppRenderQuality) pumpMemory,
) {
  for (final quality in AppRenderQuality.values) {
    testWidgets(
      'memory floating action isolates glass above scrolling cards in $quality',
      (tester) async {
        await pumpMemory(tester, quality);
        final finder = find.byKey(const ValueKey('add-memory'));
        final button = tester.widget<GlassButton>(finder);
        expect(button.useOwnLayer, isTrue);
        expect(button.quality, switch (quality) {
          AppRenderQuality.minimal => GlassQuality.minimal,
          AppRenderQuality.standard => GlassQuality.standard,
          AppRenderQuality.premium => GlassQuality.premium,
        });
        final bounds = tester.getRect(finder);
        final cards = find.byType(GlassGroupedSection);
        expect(tester.getRect(cards.first).overlaps(bounds), isTrue);
        await tester.drag(find.byType(ListView).first, const Offset(0, -150));
        await tester.pumpAndSettle();
        expect(tester.getRect(finder), bounds);
        expect(finder.hitTestable(), findsOneWidget);
        await tester.tap(finder);
        await tester.pumpAndSettle();
        expect(find.byType(MemoryEditorPage), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
