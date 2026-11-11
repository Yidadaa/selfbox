import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:selfbox/features/chat/presentation/widgets/date_labels.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('en');
    await initializeDateFormatting('zh_CN');
  });

  final now = DateTime(2026, 11, 12, 10);

  String label(DateTime day, {String locale = 'en'}) => formatDayLabel(
    day,
    now,
    locale: locale,
    today: 'TODAY',
    yesterday: 'YESTERDAY',
  );

  group('formatDayLabel', () {
    test('same calendar day is today, regardless of time', () {
      expect(label(DateTime(2026, 11, 12, 0, 1)), 'TODAY');
      expect(label(DateTime(2026, 11, 12, 23, 59)), 'TODAY');
    });

    test('previous calendar day is yesterday, even under 24h ago', () {
      expect(label(DateTime(2026, 11, 11, 23, 59)), 'YESTERDAY');
    });

    test('earlier days this year omit the year', () {
      expect(label(DateTime(2026, 8, 7)), 'Aug 7');
      expect(label(DateTime(2026, 8, 7), locale: 'zh_CN'), '8月7日');
    });

    test('other years include the year', () {
      expect(label(DateTime(2025, 8, 7)), 'Aug 7, 2025');
      expect(label(DateTime(2025, 8, 7), locale: 'zh_CN'), '2025年8月7日');
    });
  });

  group('formatClock', () {
    test('is 24-hour with leading zeros', () {
      expect(formatClock(DateTime(2026, 1, 1, 8, 5), locale: 'en'), '08:05');
      expect(formatClock(DateTime(2026, 1, 1, 21, 30), locale: 'en'), '21:30');
    });
  });
}
