import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../theme/app_glass_theme.dart';
import '../theme/app_motion.dart';

/// Diffused light behind the input glass; the foreground retains its own layer.
class AiComposerGlow extends HookConsumerWidget {
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
    final controller = useAnimationController(
      duration: AppMotion.composerGlowLoop,
    );
    final visibility = useAnimationController(
      duration: AppMotion.composerGlowEnter,
      reverseDuration: AppMotion.composerGlowExit,
    );
    final reveal = useMemoized(
      () => CurvedAnimation(
        parent: visibility,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInOutCubic,
      ),
      [visibility],
    );
    useEffect(() => reveal.dispose, [reveal]);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    useEffect(() {
      if (reduceMotion) {
        visibility.value = active ? 1 : 0;
      } else if (active) {
        visibility.forward();
      } else {
        visibility.reverse();
      }
      if (active && !reduceMotion) {
        controller.repeat();
      } else {
        controller.stop();
      }
      return null;
    }, [active, reduceMotion, controller, visibility]);

    // Keep both slots mounted when AI mode changes to preserve editor focus.
    return Stack(
      fit: StackFit.passthrough,
      children: [
        Positioned.fill(
          child: _GlowLayer(shape: shape, reveal: reveal, motion: controller),
        ),
        child,
        if (context.glass.composerAiOutline.a > 0)
          Positioned.fill(
            child: IgnorePointer(
              child: FadeTransition(
                opacity: reveal,
                child: DecoratedBox(
                  key: const ValueKey('ai-composer-outline'),
                  decoration: ShapeDecoration(
                    shape: shape.copyWith(
                      side: BorderSide(color: context.glass.composerAiOutline),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _GlowLayer extends StatelessWidget {
  const _GlowLayer({
    required this.shape,
    required this.reveal,
    required this.motion,
  });

  final LiquidShape shape;
  final Animation<double> reveal;
  final Animation<double> motion;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    return IgnorePointer(
      child: ClipPath(
        clipper: ShapeBorderClipper(shape: shape),
        child: FadeTransition(
          opacity: reveal,
          child: RotationTransition(
            turns: Tween(
              begin: AppMotion.composerGlowEntryTurns,
              end: 0.0,
            ).animate(reveal),
            child: ScaleTransition(
              scale: Tween(
                begin: AppMotion.composerGlowEntryScale,
                end: AppMotion.composerGlowRestScale,
              ).animate(reveal),
              child: RepaintBoundary(
                child: ImageFiltered(
                  imageFilter: ui.ImageFilter.blur(
                    sigmaX: glass.chromeBlur,
                    sigmaY: glass.chromeBlur,
                  ),
                  child: CustomPaint(
                    painter: _ComposerGlowPainter(
                      animation: motion,
                      colors: glass.composerGlowColors,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ComposerGlowPainter extends CustomPainter {
  _ComposerGlowPainter({required this.animation, required this.colors})
    : super(repaint: animation);

  final Animation<double> animation;
  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final phase = animation.value * math.pi * 2;
    // The warm anchor must stay visible throughout the loop; its center never
    // leaves the left third, including during the entry rotation and scale.
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
      oldDelegate.animation != animation ||
      !listEquals(oldDelegate.colors, colors);
}
