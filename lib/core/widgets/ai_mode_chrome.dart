import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../theme/app_glass_theme.dart';
import '../theme/app_motion.dart';

/// Adds a low-cost animated spectrum edge to the active AI controls.
///
/// The sweep runs when AI mode becomes active and then rests. This keeps the
/// chrome expressive without keeping a ticker alive during every idle frame.
class AiModeChrome extends HookWidget {
  const AiModeChrome({
    required this.active,
    required this.child,
    this.borderRadius = BorderRadius.zero,
    super.key,
  });

  final bool active;
  final Widget child;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    final controller = useAnimationController(duration: AppMotion.aiSweep);
    useEffect(() {
      if (active) {
        controller.forward(from: 0);
      } else {
        controller.stop();
        controller.value = 0;
      }
      return null;
    }, [active, controller]);

    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) => CustomPaint(
        key: const ValueKey('ai-mode-chrome'),
        painter: active
            ? _AiModeBorderPainter(
                progress: controller.value,
                colors: _spectrum(context.glass),
                borderRadius: borderRadius,
              )
            : null,
        child: child,
      ),
      child: child,
    );
  }

  List<Color> _spectrum(AppGlassTheme glass) => [
    glass.accent,
    Color.lerp(glass.accent, glass.canvasGradient.last, 0.35) ?? glass.accent,
    glass.canvasGradient.last,
    Color.lerp(glass.accent, glass.bubbleMine, 0.45) ?? glass.accent,
    glass.accent,
  ];
}

class _AiModeBorderPainter extends CustomPainter {
  const _AiModeBorderPainter({
    required this.progress,
    required this.colors,
    required this.borderRadius,
  });

  final double progress;
  final List<Color> colors;
  final BorderRadius borderRadius;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final rect = Offset.zero & size;
    final rrect = borderRadius.toRRect(rect).deflate(0.75);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..shader = SweepGradient(
        transform: GradientRotation(progress * math.pi * 2),
        colors: colors,
      ).createShader(rect);
    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(covariant _AiModeBorderPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.colors != colors ||
      oldDelegate.borderRadius != borderRadius;
}
