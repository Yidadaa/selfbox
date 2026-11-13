import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../../../../core/theme/app_glass_theme.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';

class AssistantStatusSurface extends HookWidget {
  const AssistantStatusSurface({
    required this.child,
    this.pending = false,
    super.key,
  });

  final Widget child;
  final bool pending;

  @override
  Widget build(BuildContext context) {
    const round = Radius.circular(AppRadius.md);
    const borderRadius = BorderRadius.only(
      topLeft: round,
      topRight: round,
      bottomRight: round,
      bottomLeft: Radius.circular(AppRadius.xs),
    );
    final pulse = useAnimationController(duration: AppMotion.statusPulse);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    useEffect(() {
      if (reduceMotion) {
        pulse.value = 1;
      } else if (pending) {
        pulse.forward(from: 0);
      }
      return null;
    }, [pending, pulse, reduceMotion]);

    final content = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: child,
    );
    if (!pending) {
      return DecoratedBox(
        decoration: BoxDecoration(
          color: context.glass.bubbleOther,
          borderRadius: borderRadius,
        ),
        child: content,
      );
    }
    return AnimatedBuilder(
      animation: pulse,
      builder: (context, child) => CustomPaint(
        key: const ValueKey('assistant-pending-surface'),
        painter: _SurfacePulsePainter(
          progress: pulse.value,
          color: context.glass.bubbleOther,
          highlight: context.glass.highlightBorder,
          borderRadius: borderRadius,
        ),
        child: child,
      ),
      child: content,
    );
  }
}

class _SurfacePulsePainter extends CustomPainter {
  const _SurfacePulsePainter({
    required this.progress,
    required this.color,
    required this.highlight,
    required this.borderRadius,
  });

  final double progress;
  final Color color;
  final Color highlight;
  final BorderRadius borderRadius;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final rect = Offset.zero & size;
    final rrect = borderRadius.toRRect(rect);
    canvas.drawRRect(rrect, Paint()..color = color);
    final sweep = size.width * 0.45;
    final start = (size.width + sweep) * progress - sweep;
    final pulseRect = Rect.fromLTWH(start, 0, sweep, size.height);
    final shader = LinearGradient(
      colors: [
        highlight.withValues(alpha: 0),
        highlight.withValues(alpha: 0.22),
        highlight.withValues(alpha: 0),
      ],
    ).createShader(pulseRect);
    canvas.save();
    canvas.clipRRect(rrect);
    canvas.drawRect(pulseRect, Paint()..shader = shader);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _SurfacePulsePainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.color != color ||
      oldDelegate.highlight != highlight ||
      oldDelegate.borderRadius != borderRadius;
}
