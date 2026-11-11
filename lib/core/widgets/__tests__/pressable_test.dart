import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:selfbox/core/testing/app_widget_tester.dart';
import 'package:selfbox/core/theme/app_motion.dart';
import 'package:selfbox/core/theme/app_spacing.dart';
import 'package:selfbox/core/widgets/pressable.dart';

void main() {
  group('Pressable', () {
    testWidgets('expands a small child to the 48dp touch target', (
      tester,
    ) async {
      await tester.pumpPage(
        Center(
          child: Pressable(
            onTap: () {},
            child: const SizedBox(width: 16, height: 16),
          ),
        ),
      );

      final size = tester.getSize(find.byType(Pressable));
      expect(size.width, greaterThanOrEqualTo(AppSizes.minTouchTarget));
      expect(size.height, greaterThanOrEqualTo(AppSizes.minTouchTarget));
    });

    testWidgets('fires onTap and scales down while pressed', (tester) async {
      var taps = 0;
      await tester.pumpPage(
        Center(
          child: Pressable(onTap: () => taps++, child: const Text('x')),
        ),
      );

      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(Pressable)),
      );
      await tester.pump(AppMotion.press);
      expect(
        tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale,
        AppMotion.pressScale,
      );

      await gesture.up();
      await tester.pumpAndSettle();
      expect(taps, 1);
      expect(tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale, 1);
    });

    testWidgets('fires onLongPress', (tester) async {
      var longPresses = 0;
      await tester.pumpPage(
        Center(
          child: Pressable(
            onTap: null,
            onLongPress: () => longPresses++,
            child: const Text('x'),
          ),
        ),
      );

      await tester.longPress(find.byType(Pressable));
      expect(longPresses, 1);
    });

    testWidgets('is announced as a disabled button without callbacks', (
      tester,
    ) async {
      await tester.pumpPage(
        const Center(
          child: Pressable(
            onTap: null,
            semanticLabel: 'Send',
            child: Icon(Icons.send),
          ),
        ),
      );

      expect(
        tester.getSemantics(find.byType(Pressable)),
        matchesSemantics(label: 'Send', isButton: true, hasEnabledState: true),
      );
    });
  });
}
