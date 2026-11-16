import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../providers/chat_scroll_controller.dart';
import '../providers/chat_timeline.dart';
import '../providers/composer_controller.dart';

typedef TimelineAnchor = ({int? messageId, double alignment});

({
  TimelineAnchor anchor,
  GlobalKey Function(int) keyFor,
  void Function(int) prefer,
})
useTimelineAnchor(
  WidgetRef ref,
  List<ChatTimelineItem> items,
  ChatScrollController scroll,
  GlobalKey viewportKey,
) {
  final keys = useMemoized(() => <int, GlobalKey>{});
  useEffect(() {
    final ids = {
      for (final item in items)
        if (item case TimelineMessage(:final message)) message.id,
    };
    keys.removeWhere((id, _) => !ids.contains(id));
    return null;
  }, [items]);
  final anchor = useRef<TimelineAnchor>((messageId: null, alignment: 0));
  final bottomRequest = useValueListenable(scroll.bottomRequests);
  useEffect(() {
    if (bottomRequest == 0) return null;
    anchor.value = (messageId: null, alignment: 0);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scroll.hasClients) scroll.jumpTo(scroll.position.minScrollExtent);
    });
    return null;
  }, [bottomRequest]);
  final preferred = useRef<int?>(null);
  ref.listen(composerControllerProvider.select((state) => state.aiMode), (
    previous,
    next,
  ) {
    if (previous == next || !scroll.hasClients) return;
    final viewport = viewportKey.currentContext?.findRenderObject();
    if (viewport is! RenderBox || !viewport.hasSize) return;
    final candidates = <int>[
      if (preferred.value case final int id) id,
      if (anchor.value.messageId case final int id) id,
      for (var index = 1; index < items.length; index++)
        if (items[index] case TimelineMessage(:final message)
            when items[index - 1] is TimelineAiGroup)
          message.id,
    ];
    preferred.value = null;
    for (final id in candidates) {
      final row = keys[id]?.currentContext?.findRenderObject();
      if (row is! RenderBox || !row.hasSize) continue;
      final top = row.localToGlobal(Offset.zero, ancestor: viewport).dy;
      if (top < 0 || top > viewport.size.height) continue;
      anchor.value = (messageId: id, alignment: 1 - top / viewport.size.height);
      scroll.jumpTo(0);
      return;
    }
  });
  return (
    anchor: anchor.value,
    keyFor: (id) => keys.putIfAbsent(id, GlobalKey.new),
    prefer: (id) => preferred.value = id,
  );
}
