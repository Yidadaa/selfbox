import 'package:flutter/gestures.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:selfbox/core/theme/sdk_material.dart';

/// Observes taps without delaying child buttons, image taps or text selection.
class ChatTimestampGesture extends HookWidget {
  const ChatTimestampGesture({
    required this.onDoubleTap,
    required this.child,
    required this.enabled,
    super.key,
  });

  final VoidCallback onDoubleTap;
  final Widget child;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final down = useRef<PointerDownEvent?>(null);
    final previous = useRef<PointerUpEvent?>(null);
    useEffect(() {
      down.value = null;
      previous.value = null;
      return null;
    }, [enabled]);
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (event) {
        if (!enabled) return;
        if (down.value != null || event.buttons != kPrimaryButton) {
          down.value = null;
          previous.value = null;
          return;
        }
        down.value = event;
      },
      onPointerMove: (event) {
        final start = down.value;
        if (start == null || start.pointer != event.pointer) return;
        if ((start.position - event.position).distance > kTouchSlop) {
          down.value = null;
          previous.value = null;
        }
      },
      onPointerCancel: (_) {
        down.value = null;
        previous.value = null;
      },
      onPointerUp: (event) {
        final start = down.value;
        final last = previous.value;
        down.value = null;
        if (start == null ||
            start.pointer != event.pointer ||
            (start.position - event.position).distance > kTouchSlop ||
            event.timeStamp - start.timeStamp >= kLongPressTimeout) {
          previous.value = null;
          return;
        }
        previous.value = event;
        if (last == null) return;
        if (start.kind != last.kind || start.device != last.device) return;
        final elapsed = start.timeStamp - last.timeStamp;
        if (elapsed >= kDoubleTapMinTime &&
            elapsed <= kDoubleTapTimeout &&
            (start.position - last.position).distance <= kDoubleTapSlop) {
          onDoubleTap();
        }
      },
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusScope.of(context).unfocus(),
        child: child,
      ),
    );
  }
}
