import 'package:flutter_test/flutter_test.dart';
import 'package:selfbox/features/chat/domain/models/message.dart';
import 'package:selfbox/features/chat/presentation/providers/chat_scroll_controller.dart';

import '../../../../support/app_widget_tester.dart';

List<Message> olderHistory() => [
  for (var id = 101; id <= 108; id++)
    Message(
      id: id,
      author: MessageAuthor.me,
      text: 'History $id',
      createdAt: kTestNow.subtract(Duration(minutes: id)),
    ),
];

Future<void> hideLatest(
  WidgetTester tester,
  ChatScrollController scroll,
  Finder latest,
) async {
  scroll.jumpTo(
    scroll.offset + kPhoneViewport.height - tester.getTopLeft(latest).dy + 8,
  );
  await tester.pumpAndSettle();
  if (latest.evaluate().isNotEmpty) {
    expect(tester.getTopLeft(latest).dy, greaterThan(kPhoneViewport.height));
  }
}
