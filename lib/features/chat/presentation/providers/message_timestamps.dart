import '../../domain/models/message.dart';
import 'chat_timeline.dart';

/// Keeps the newest timestamp in each visible run of a local calendar minute.
Set<int> messageTimestampIds(
  List<ChatTimelineItem> items, {
  required bool aiMode,
}) {
  final ids = <int>{};
  DateTime? newerMinute;

  void visit(Message message) {
    final local = message.createdAt.toLocal();
    final minute = DateTime(
      local.year,
      local.month,
      local.day,
      local.hour,
      local.minute,
    );
    if (minute != newerMinute) ids.add(message.id);
    newerMinute = minute;
  }

  for (final item in items) {
    switch (item) {
      case TimelineMessage(:final message):
        visit(message);
      case TimelineAiGroup(:final messages):
        if (aiMode) {
          messages.forEach(visit);
        } else {
          // A hidden group is a visible separator, not an invisible timestamp.
          newerMinute = null;
        }
      case TimelineDay():
        newerMinute = null;
    }
  }
  return Set.unmodifiable(ids);
}
