import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../theme/app_effects.dart';
import '../theme/app_glass_theme.dart';
import '../theme/app_motion.dart';

/// Static diffused light behind the input glass.
class AiComposerGlow extends ConsumerWidget {
  const AiComposerGlow({
    required this.active,
    required this.shape,
    required this.child,
    super.key,
  });

  final bool active;
  final LiquidShape shape;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final glass = context.glass;
    // Stable slots preserve the editor and its focus when AI mode changes.
    return Stack(
      fit: StackFit.passthrough,
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              key: const ValueKey('composer-solid-background'),
              decoration: ShapeDecoration(
                color: AppEffects.isMinimal(context)
                    ? AppEffects.solidSurface(context)
                    : null,
                shape: shape,
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: Visibility(
              visible: active,
              child: ClipPath(
                clipper: ShapeBorderClipper(shape: shape),
                child: Transform.scale(
                  scale: AppMotion.composerGlowRestScale,
                  child: RepaintBoundary(
                    child: CustomPaint(
                      painter: _ComposerGlowPainter(
                        colors: glass.composerGlowColors,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: ShapeDecoration(
                color: AppEffects.isMinimal(context) && active
                    ? glass.composerAiTint
                    : null,
                shape: shape,
              ),
            ),
          ),
        ),
        child,
        if (AppEffects.isMinimal(context) ||
            (active && glass.composerAiOutline.a > 0))
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                key: const ValueKey('ai-composer-outline'),
                decoration: ShapeDecoration(
                  shape: shape.copyWith(
                    side: AppEffects.isMinimal(context)
                        ? AppEffects.solidBorderOf(context)
                        : BorderSide(color: glass.composerAiOutline),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _ComposerGlowPainter extends CustomPainter {
  _ComposerGlowPainter({required this.colors});

  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    const phase = 0.0;
    // Freeze the original resting palette, including its warm left anchor.
    final centers = [
      Offset(
        size.width * (0.22 + 0.06 * math.sin(phase)),
        size.height * (0.56 + 0.12 * math.cos(phase)),
      ),
      Offset(
        size.width * (0.46 + 0.06 * math.cos(phase + 1.8)),
        size.height * (0.36 + 0.12 * math.sin(phase)),
      ),
      Offset(
        size.width * (0.70 + 0.06 * math.sin(phase + 3.1)),
        size.height * (0.70 + 0.10 * math.cos(phase + 1.2)),
      ),
      Offset(
        size.width * (0.88 + 0.04 * math.cos(phase + 4.2)),
        size.height * (0.30 + 0.10 * math.sin(phase + 2.4)),
      ),
    ];
    final radius = size.width * 0.48;
    for (var index = 0; index < centers.length; index++) {
      final color = colors[index];
      final rect = Rect.fromCircle(center: centers[index], radius: radius);
      final paint = Paint()
        ..shader = RadialGradient(colors: [color, color.withValues(alpha: 0)])
            .createShader(rect);
      canvas.drawCircle(centers[index], radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ComposerGlowPainter oldDelegate) =>
      !listEquals(oldDelegate.colors, colors);
}
