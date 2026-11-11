import 'package:intl/intl.dart';

/// "今天" / "昨天" / "8月7日" / "2025年8月7日" depending on distance from [now].
String formatDayLabel(
  DateTime day,
  DateTime now, {
  required String locale,
  required String today,
  required String yesterday,
}) {
  final d = DateTime(day.year, day.month, day.day);
  final n = DateTime(now.year, now.month, now.day);
  final diff = n.difference(d).inDays;
  if (diff == 0) return today;
  if (diff == 1) return yesterday;
  final format = d.year == n.year
      ? DateFormat.MMMd(locale)
      : DateFormat.yMMMd(locale);
  return format.format(d);
}

String formatClock(DateTime time, {required String locale}) =>
    DateFormat.Hm(locale).format(time.toLocal());
