import 'dart:typed_data';

import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:selfbox/core/theme/sdk_material.dart';
import 'package:selfbox/core/widgets/ai_composer_glow.dart';

import '../../support/app_widget_tester.dart';

const _observationPeriod = Duration(seconds: 12);
const _capture = ValueKey('glow-capture');
const _shape = LiquidRoundedSuperellipse(borderRadius: 36);

Widget _fixture({required bool active}) => Center(
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
  testWidgets('AI light switches instantly without moving the input', (
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
    expect(await _pixels(tester), isNot(orderedEquals(before)));
    expect(tester.binding.hasScheduledFrame, isFalse);
    enabled.value = false;
    await tester.pump();
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

  testWidgets('glow stays static across time and background transitions', (
    tester,
  ) async {
    await tester.pumpPage(_fixture(active: true), settle: false);
    final bounds = tester.getRect(find.byType(AiComposerGlow));
    final first = await _pixels(tester);
    await tester.pump(_observationPeriod);
    expect(await _pixels(tester), orderedEquals(first));
    expect(tester.binding.hasScheduledFrame, isFalse);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump(const Duration(seconds: 30));
    expect(tester.binding.hasScheduledFrame, isFalse);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(await _pixels(tester), orderedEquals(first));
    expect(tester.getRect(find.byType(AiComposerGlow)), bounds);

    await tester.pumpPage(_fixture(active: false));
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  for (final (brightness, height) in [
    (Brightness.light, 48.0),
    (Brightness.light, 128.0),
    (Brightness.dark, 48.0),
    (Brightness.dark, 128.0),
  ]) {
    testWidgets('static coral stays visible in $brightness at $height dp', (
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
        brightness: brightness,
        settle: false,
      );
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
        reason: 'Missing coral in $brightness at $height dp',
      );
    });
  }
}
