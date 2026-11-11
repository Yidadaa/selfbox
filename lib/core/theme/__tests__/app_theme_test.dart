import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:selfbox/core/theme/app_glass_theme.dart';
import 'package:selfbox/core/theme/app_radius.dart';
import 'package:selfbox/core/theme/app_scroll_behavior.dart';
import 'package:selfbox/core/theme/app_spacing.dart';
import 'package:selfbox/core/theme/app_theme.dart';

double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final (hi, lo) = la > lb ? (la, lb) : (lb, la);
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  group('AppSpacing', () {
    test('every step sits on the 4pt grid', () {
      for (final step in AppSpacing.scale) {
        expect(step % 4, 0, reason: '$step is off-grid');
      }
    });

    test('scale is strictly ascending and matches the spec', () {
      expect(AppSpacing.scale, [4, 8, 12, 16, 20, 24, 32, 40, 48]);
    });

    test('minimum touch target is 48dp', () {
      expect(AppSizes.minTouchTarget, 48);
    });
  });

  group('AppRadius.concentric', () {
    test('subtracts padding from the outer radius', () {
      expect(AppRadius.concentric(outer: 28, padding: 12), 16);
    });

    test('never drops below the minimum inner radius', () {
      expect(AppRadius.concentric(outer: 20, padding: 16), AppRadius.minInner);
      expect(AppRadius.concentric(outer: 8, padding: 24), AppRadius.minInner);
    });
  });

  group('AppTheme', () {
    for (final (name, theme, brightness) in [
      ('dark', AppTheme.dark(), Brightness.dark),
      ('light', AppTheme.light(), Brightness.light),
    ]) {
      group(name, () {
        final glass = theme.extension<AppGlassTheme>();

        test('mounts the matching AppGlassTheme extension', () {
          expect(theme.brightness, brightness);
          expect(glass, same(AppGlassTheme.of(brightness)));
        });

        test('chrome layer blurs more than the surface layer', () {
          expect(glass!.chromeBlur, greaterThan(glass.surfaceBlur));
        });

        test('foreground text meets WCAG AA on every canvas stop', () {
          for (final canvas in glass!.canvasGradient) {
            final surface = Color.alphaBlend(glass.surfaceTint, canvas);
            expect(_contrast(glass.foreground, surface), greaterThan(4.5));
            expect(
              _contrast(
                Color.alphaBlend(glass.foregroundMuted, surface),
                surface,
              ),
              greaterThan(4.5),
            );
          }
        });

        test('bubble text meets WCAG AA on both bubble colors', () {
          expect(
            _contrast(glass!.onBubbleMine, glass.bubbleMine),
            greaterThan(4.5),
          );
          expect(
            _contrast(glass.onBubbleOther, glass.bubbleOther),
            greaterThan(4.5),
          );
        });

        test('uses one page transition on every platform', () {
          final builders = theme.pageTransitionsTheme.builders;
          expect(builders.keys.toSet(), TargetPlatform.values.toSet());
          expect(
            builders.values.map((b) => b.runtimeType).toSet(),
            hasLength(1),
          );
        });
      });
    }
  });

  group('AppGlassTheme.lerp', () {
    test('endpoints return the source and target values', () {
      const a = AppGlassTheme.dark;
      const b = AppGlassTheme.light;
      expect(a.lerp(b, 0).foreground, a.foreground);
      expect(a.lerp(b, 1).foreground, b.foreground);
      expect(a.lerp(b, 1).canvasGradient, b.canvasGradient);
    });

    test('lerping toward null keeps the current theme', () {
      expect(AppGlassTheme.dark.lerp(null, 0.5), same(AppGlassTheme.dark));
    });
  });

  group('context.glass', () {
    testWidgets('falls back to the brightness default without the extension', (
      tester,
    ) async {
      late AppGlassTheme resolved;
      await tester.pumpWidget(
        Theme(
          data: ThemeData(brightness: Brightness.light),
          child: Builder(
            builder: (context) {
              resolved = context.glass;
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      expect(resolved, same(AppGlassTheme.light));
    });
  });

  group('AppScrollBehavior', () {
    testWidgets('bounces on every platform', (tester) async {
      late ScrollPhysics physics;
      await tester.pumpWidget(
        Builder(
          builder: (context) {
            physics = const AppScrollBehavior().getScrollPhysics(context);
            return const SizedBox.shrink();
          },
        ),
      );
      expect(physics, isA<BouncingScrollPhysics>());
      expect(physics.parent, isA<AlwaysScrollableScrollPhysics>());
    });
  });
}
