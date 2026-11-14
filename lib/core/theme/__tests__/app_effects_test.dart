import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:selfbox/core/testing/app_widget_tester.dart';
import 'package:selfbox/core/theme/app_effects.dart';
import 'package:selfbox/core/widgets/ai_composer_glow.dart';
import 'package:skeletonizer/skeletonizer.dart';

void main() {
  for (final selected in GlassQuality.values) {
    testWidgets('content and chrome respect the $selected budget', (
      tester,
    ) async {
      await tester.pumpPage(
        AppEffects(
          quality: selected,
          animationsEnabled: true,
          child: const Text('probe'),
        ),
      );
      final context = tester.element(find.text('probe'));
      expect(
        AppEffects.qualityOf(context, GlassQuality.standard),
        selected == GlassQuality.minimal ? selected : GlassQuality.standard,
      );
      expect(AppEffects.qualityOf(context, GlassQuality.premium), selected);
      expect(
        GlassThemeData.of(context).qualityFor(context),
        selected == GlassQuality.minimal ? selected : GlassQuality.standard,
      );
    });
  }
  testWidgets('disabling motion stops active glow and skeleton loops', (
    tester,
  ) async {
    final enabled = ValueNotifier(true);
    addTearDown(enabled.dispose);
    await tester.pumpPage(
      ValueListenableBuilder(
        valueListenable: enabled,
        builder: (_, value, child) => AppEffects(
          quality: GlassQuality.standard,
          animationsEnabled: value,
          child: child!,
        ),
        child: const Column(
          children: [
            AiComposerGlow(
              active: true,
              shape: LiquidRoundedSuperellipse(borderRadius: 24),
              child: SizedBox(width: 300, height: 100),
            ),
            Skeletonizer(child: Text('Loading')),
          ],
        ),
      ),
      settle: false,
    );
    expect(tester.binding.hasScheduledFrame, isTrue);
    enabled.value = false;
    await tester.pumpAndSettle();
    expect(tester.binding.hasScheduledFrame, isFalse);
    expect(
      tester.widget<AiComposerGlow>(find.byType(AiComposerGlow)).active,
      isTrue,
    );
    enabled.value = true;
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.binding.hasScheduledFrame, isTrue);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('user enabled animations still respect system reduced motion', (
    tester,
  ) async {
    await tester.pumpPage(
      const MediaQuery(
        data: MediaQueryData(disableAnimations: true),
        child: AppEffects(
          quality: GlassQuality.minimal,
          animationsEnabled: true,
          child: Text('probe'),
        ),
      ),
    );
    final context = tester.element(find.text('probe'));
    expect(MediaQuery.disableAnimationsOf(context), isTrue);
    expect(GlassAccessibilityData.of(context).reduceMotion, isTrue);
  });
}
