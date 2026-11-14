import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/image_viewer_tokens.dart';

({
  TransformationController transform,
  bool zoomed,
  VoidCallback stop,
  GestureTapDownCallback onTapDown,
  VoidCallback onDoubleTap,
})
useImageZoom(BuildContext context) {
  final transform = useTransformationController();
  final animation = useAnimationController(duration: AppMotion.medium);
  final tween = useRef<Matrix4Tween?>(null);
  final tap = useRef(Offset.zero);
  final reducedMotion = MediaQuery.disableAnimationsOf(context);
  useEffect(() {
    void tick() {
      final value = tween.value;
      if (value != null) {
        transform.value = value.transform(
          AppMotion.emphasized.transform(animation.value),
        );
      }
    }

    animation.addListener(tick);
    return () => animation.removeListener(tick);
  }, [animation, transform]);
  useEffect(() {
    if (reducedMotion && animation.isAnimating) {
      animation.value = 1;
      animation.stop();
    }
    return null;
  }, [reducedMotion]);
  final zoomed = useListenableSelector(
    transform,
    () => transform.value.getMaxScaleOnAxis() > ImageViewerTokens.zoomTolerance,
  );
  return (
    transform: transform,
    zoomed: zoomed,
    stop: animation.stop,
    onTapDown: (details) => tap.value = details.localPosition,
    onDoubleTap: () {
      final target = zoomed
          ? Matrix4.identity()
          : (Matrix4.identity()
              ..translateByDouble(
                tap.value.dx * (1 - ImageViewerTokens.doubleTapZoom),
                tap.value.dy * (1 - ImageViewerTokens.doubleTapZoom),
                0,
                1,
              )
              ..scaleByDouble(
                ImageViewerTokens.doubleTapZoom,
                ImageViewerTokens.doubleTapZoom,
                1,
                1,
              ));
      animation.stop();
      if (reducedMotion) {
        transform.value = target;
        return;
      }
      tween.value = Matrix4Tween(begin: transform.value.clone(), end: target);
      animation.forward(from: 0);
    },
  );
}

({
  GestureScaleStartCallback start,
  GestureScaleUpdateCallback update,
  GestureScaleEndCallback end,
})
useImagePaging(
  BuildContext context,
  PageController? pager,
  TransformationController transform,
  VoidCallback stopZoom,
) {
  final origin = useRef<int?>(null);
  final reducedMotion = MediaQuery.disableAnimationsOf(context);
  return (
    start: (details) {
      stopZoom();
      if (transform.value.getMaxScaleOnAxis() >
              ImageViewerTokens.zoomTolerance ||
          details.pointerCount != 1 ||
          pager == null ||
          !pager.hasClients) {
        return;
      }
      origin.value = pager.page?.round() ?? 0;
    },
    update: (details) {
      final start = origin.value;
      if (start == null || pager == null || !pager.hasClients) return;
      if (details.pointerCount > 1) {
        origin.value = null;
        pager.jumpToPage(start);
        return;
      }
      // ScrollPosition.drag makes Scrollable ignore new pointers. Keep the
      // pager interactive so a second finger can join an existing swipe.
      pager.jumpTo(
        (pager.offset - details.focalPointDelta.dx).clamp(
          pager.position.minScrollExtent,
          pager.position.maxScrollExtent,
        ),
      );
    },
    end: (details) {
      final start = origin.value;
      origin.value = null;
      if (start == null || pager == null || !pager.hasClients) return;
      if (details.pointerCount > 0) {
        pager.jumpToPage(start);
        return;
      }
      final velocity = details.velocity.pixelsPerSecond.dx;
      final page = pager.page ?? start.toDouble();
      final target = velocity.abs() >= kMinFlingVelocity
          ? start + (velocity < 0 ? 1 : -1)
          : page.round();
      final last =
          (pager.position.maxScrollExtent / pager.position.viewportDimension)
              .round();
      final destination = target.clamp(0, last);
      if (reducedMotion) {
        pager.jumpToPage(destination);
      } else {
        pager.animateToPage(
          destination,
          duration: AppMotion.medium,
          curve: AppMotion.emphasized,
        );
      }
    },
  );
}
