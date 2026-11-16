import 'package:flutter/widgets.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part '../../../../gen/features/chat/presentation/providers/chat_scroll_controller.g.dart';

@riverpod
ChatScrollController chatScrollController(Ref ref) {
  final controller = ChatScrollController();
  ref.onDispose(controller.dispose);
  return controller;
}

class ChatScrollController extends ScrollController {
  final bottomRequests = ValueNotifier(0);

  void requestBottom() => bottomRequests.value++;

  @override
  void dispose() {
    bottomRequests.dispose();
    super.dispose();
  }

  @override
  ScrollPosition createScrollPosition(
    ScrollPhysics physics,
    ScrollContext context,
    ScrollPosition? oldPosition,
  ) => _ChatScrollPosition(
    physics: physics,
    context: context,
    oldPosition: oldPosition,
    onMetricsChanged: notifyListeners,
  );
}

class _ChatScrollPosition extends ScrollPositionWithSingleContext {
  _ChatScrollPosition({
    required super.physics,
    required super.context,
    required super.oldPosition,
    required this.onMetricsChanged,
  });

  final VoidCallback onMetricsChanged;

  @override
  void didUpdateScrollMetrics() {
    super.didUpdateScrollMetrics();
    if (context.notificationContext?.mounted ?? false) onMetricsChanged();
  }
}
