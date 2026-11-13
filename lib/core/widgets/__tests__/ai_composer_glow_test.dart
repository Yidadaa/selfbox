import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:selfbox/core/testing/app_widget_tester.dart';
import 'package:selfbox/core/theme/app_motion.dart';
import 'package:selfbox/core/widgets/ai_composer_glow.dart';

const _capture = ValueKey('glow-capture');
const _shape = LiquidRoundedSuperellipse(borderRadius: 36);

Widget _fixture({required bool active, bool reduceMotion = false}) =>
    MediaQuery(
      data: MediaQueryData(disableAnimations: reduceMotion),
      child: Center(
        child: RepaintBoundary(
          key: _capture,
          child: ColoredBox(
            color: const Color(0xFFF0EFF4),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: AiComposerGlow(
                active: active,
                shape: _shape,
                child: const SizedBox(width: 320, height: 128),
              ),
            ),
          ),
        ),
      ),
    );

Future<Uint8List> _pixels(WidgetTester tester) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_capture),
  );
  final pixels = await tester.runAsync(() async {
    final image = await boundary.toImage();
    final data = await image.toByteData();
    image.dispose();
    return data?.buffer.asUint8List();
  });
  expect(pixels, isNotNull);
  return pixels ?? Uint8List(0);
}

void main() {
  testWidgets('AI light animates in and out without moving the input', (
    tester,
  ) async {
    final enabled = ValueNotifier(false);
    addTearDown(enabled.dispose);
    await tester.pumpPage(
      ValueListenableBuilder(
        valueListenable: enabled,
        builder: (_, active, _) => _fixture(active: active),
      ),
    );
    final bounds = tester.getRect(find.byType(AiComposerGlow));
    final before = await _pixels(tester);
    enabled.value = true;
    await tester.pump();
    await tester.pump(AppMotion.composerGlowEnter ~/ 2);
    final fade = find
        .descendant(
          of: find.byType(AiComposerGlow),
          matching: find.byType(FadeTransition),
        )
        .first;
    expect(
      tester.widget<FadeTransition>(fade).opacity.value,
      inExclusiveRange(0, 1),
    );
    expect(await _pixels(tester), isNot(orderedEquals(before)));
    await tester.pump(AppMotion.composerGlowEnter);
    expect(tester.widget<FadeTransition>(fade).opacity.value, 1);

    enabled.value = false;
    await tester.pump();
    await tester.pump(AppMotion.composerGlowExit ~/ 2);
    expect(
      tester.widget<FadeTransition>(fade).opacity.value,
      inExclusiveRange(0, 1),
    );
    expect(await _pixels(tester), isNot(orderedEquals(before)));
    enabled.value = true;
    await tester.pump();
    await tester.pump(AppMotion.composerGlowEnter ~/ 2);
    expect(tester.widget<FadeTransition>(fade).opacity.value, greaterThan(0));
    enabled.value = false;
    await tester.pumpAndSettle();
    expect(await _pixels(tester), orderedEquals(before));
    expect(tester.getRect(find.byType(AiComposerGlow)), bounds);
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  testWidgets('glow changes only pixels inside the composer shape', (
    tester,
  ) async {
    await tester.pumpPage(_fixture(active: false));
    final before = await _pixels(tester);
    await tester.pumpPage(_fixture(active: true), settle: false);
    final after = await _pixels(tester);
    final size = tester.getSize(find.byKey(_capture));
    final path = _shape.getOuterPath(const Rect.fromLTWH(16, 16, 320, 128));
    final antialiasBounds = _shape.getOuterPath(
      const Rect.fromLTWH(16, 16, 320, 128).inflate(2),
    );
    var changedInside = 0;

    for (var y = 0; y < size.height; y++) {
      for (var x = 0; x < size.width; x++) {
        final offset = (y * size.width.toInt() + x) * 4;
        final changed =
            before[offset] != after[offset] ||
            before[offset + 1] != after[offset + 1] ||
            before[offset + 2] != after[offset + 2];
        if (path.contains(Offset(x + 0.5, y + 0.5))) {
          if (changed) changedInside++;
        } else {
          if (!antialiasBounds.contains(Offset(x + 0.5, y + 0.5))) {
            expect(changed, isFalse, reason: 'Glow escaped at $x, $y');
          }
        }
      }
    }
    expect(changedInside, greaterThan(1000));
  });

  testWidgets('glow keeps moving across multiple cycles without resizing', (
    tester,
  ) async {
    await tester.pumpPage(_fixture(active: true), settle: false);
    final bounds = tester.getRect(find.byType(AiComposerGlow));
    final first = await _pixels(tester);
    await tester.pump(AppMotion.composerGlowLoop ~/ 4);
    final second = await _pixels(tester);
    expect(second, isNot(orderedEquals(first)));
    await tester.pump(AppMotion.composerGlowLoop * 2);
    await tester.pump(AppMotion.composerGlowLoop ~/ 4);
    final third = await _pixels(tester);
    expect(third, isNot(orderedEquals(second)));
    expect(tester.getRect(find.byType(AiComposerGlow)), bounds);

    await tester.pumpPage(_fixture(active: false));
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  testWidgets('reduced motion keeps a static glow without an active ticker', (
    tester,
  ) async {
    await tester.pumpPage(_fixture(active: true, reduceMotion: true));
    final first = await _pixels(tester);
    await tester.pump(AppMotion.composerGlowLoop);
    expect(await _pixels(tester), orderedEquals(first));
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  for (final height in [48.0, 128.0]) {
    testWidgets('warm light stays visible throughout the $height dp loop', (
      tester,
    ) async {
      await tester.pumpPage(
        Center(
          child: RepaintBoundary(
            key: _capture,
            child: ColoredBox(
              color: const Color(0xFFF0EFF4),
              child: AiComposerGlow(
                active: true,
                shape: _shape,
                child: SizedBox(width: 320, height: height),
              ),
            ),
          ),
        ),
        brightness: Brightness.light,
        settle: false,
      );
      for (var phase = 0; phase < 16; phase++) {
        final pixels = await _pixels(tester);
        var warmPixels = 0;
        for (var y = 12; y < height - 12; y++) {
          for (var x = 32; x < 112; x++) {
            final offset = (y * 320 + x) * 4;
            if (pixels[offset] > pixels[offset + 1] + 3 &&
                pixels[offset] > pixels[offset + 2] + 3) {
              warmPixels++;
            }
          }
        }
        expect(
          warmPixels,
          greaterThan(120),
          reason: 'Missing coral at phase $phase',
        );
        await tester.pump(AppMotion.composerGlowLoop ~/ 16);
      }
    });
  }
}
