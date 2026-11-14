import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../core/router/app_routes.dart';
import '../providers/chat_feed.dart';
import '../providers/composer_controller.dart';
import '../providers/message_timestamps.dart';
import 'chat_timestamp_gesture.dart';

class ChatTimestampSession extends HookConsumerWidget {
  const ChatTimestampSession({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final delegate = GoRouter.maybeOf(context)?.routerDelegate;
    useListenable(delegate);
    final active =
        delegate == null ||
        delegate.currentConfiguration.lastOrNull?.route.path ==
            const ChatRoute().location;
    final showSeconds = useState(false);
    useEffect(() {
      // Shell branches stay mounted, including underneath pushed routes.
      if (!active) showSeconds.value = false;
      return null;
    }, [active]);

    final items = ref.watch(chatFeedProvider).value?.items ?? const [];
    final aiMode = ref.watch(
      composerControllerProvider.select((state) => state.aiMode),
    );
    final timestampIds = useMemoized(
      () => messageTimestampIds(items, aiMode: aiMode),
      [items, aiMode],
    );
    return ChatTimestampGesture(
      enabled: active,
      onDoubleTap: () => showSeconds.value = true,
      child: ChatTimestampScope(
        showSeconds: showSeconds.value,
        timestampIds: timestampIds,
        child: child,
      ),
    );
  }
}

class ChatTimestampScope extends InheritedWidget {
  const ChatTimestampScope({
    required this.showSeconds,
    required this.timestampIds,
    required super.child,
    super.key,
  });

  final bool showSeconds;
  final Set<int> timestampIds;

  static ChatTimestampScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ChatTimestampScope>();

  @override
  bool updateShouldNotify(ChatTimestampScope oldWidget) =>
      showSeconds != oldWidget.showSeconds ||
      timestampIds != oldWidget.timestampIds;
}
