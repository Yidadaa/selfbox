import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:selfbox/features/chat/domain/models/message.dart';
import 'package:selfbox/features/chat/presentation/providers/chat_scroll_controller.dart';
import 'package:selfbox/features/chat/presentation/providers/composer_controller.dart';
import 'package:selfbox/features/chat/presentation/widgets/chat_timeline_message_row.dart';

import '../../../../support/app_widget_tester.dart';
import '../../../../support/fake_message_repository.dart';

void main() {
  testWidgets(
    'visible latest overrides a card anchor across repeated toggles',
    (tester) async {
      final container = await tester.pumpApp(
        messages: FakeMessageRepository(
          seed: [
            for (var id = 1; id <= 40; id++)
              Message(
                id: id,
                createdAt: kTestNow.add(Duration(seconds: id)),
                author: id >= 25 && id <= 35
                    ? MessageAuthor.ai
                    : MessageAuthor.me,
                text: 'Message $id',
              ),
          ],
        ),
      );
      final scroll = container.read(chatScrollControllerProvider);
      scroll.jumpTo(40);
      await tester.pumpAndSettle();
      final latest = find.byWidgetPredicate(
        (widget) => widget is ChatTimelineMessageRow && widget.message.id == 40,
      );
      expect(
        tester.getRect(latest).overlaps(const Offset(0, 0) & kPhoneViewport),
        isTrue,
      );
      await tester.tap(find.byKey(const ValueKey('hidden-ai-group')));
      await tester.pump();
      expect(scroll.position.extentBefore, closeTo(0, 1));
      await tester.pumpAndSettle();
      for (var toggle = 0; toggle < 4; toggle++) {
        scroll.jumpTo(40);
        await tester.pumpAndSettle();
        container.read(composerControllerProvider.notifier).toggleAiMode();
        await tester.pump();
        expect(scroll.position.extentBefore, closeTo(0, 1));
        await tester.pumpAndSettle();
        expect(scroll.position.extentBefore, closeTo(0, 1));
      }
      expect(tester.takeException(), isNull);
    },
  );
  for (final aiMode in [false, true]) {
    for (final latestAi in [false, true]) {
      for (final partial in [false, true]) {
        testWidgets(
          'visible latest wins over anchor ai=$aiMode latestAi=$latestAi partial=$partial',
          (tester) async {
            final container = await tester.pumpApp(
              messages: FakeMessageRepository(
                seed: [
                  for (var id = 1; id <= 40; id++)
                    Message(
                      id: id,
                      createdAt: kTestNow.add(Duration(seconds: id)),
                      author: id == 40 && latestAi || id >= 25 && id <= 30
                          ? MessageAuthor.ai
                          : MessageAuthor.me,
                      text: 'Message $id',
                    ),
                ],
              ),
            );
            final composer = container.read(
              composerControllerProvider.notifier,
            );
            if (aiMode) {
              composer.toggleAiMode();
              await tester.pumpAndSettle();
            }
            final scroll = container.read(chatScrollControllerProvider);
            final latest = latestAi && !aiMode
                ? find.byKey(const ValueKey('hidden-ai-group')).first
                : find.byWidgetPredicate(
                    (widget) =>
                        widget is ChatTimelineMessageRow &&
                        widget.message.id == 40,
                  );
            final initial = tester.getRect(latest);
            final targetTop = partial
                ? kPhoneViewport.height - 4
                : initial.top + 40;
            scroll.jumpTo(scroll.offset + targetTop - initial.top);
            await tester.pumpAndSettle();
            expect(scroll.position.extentBefore, greaterThan(0));
            expect(tester.getRect(latest).top, lessThan(kPhoneViewport.height));
            if (partial) {
              expect(
                tester.getRect(latest).bottom,
                greaterThan(kPhoneViewport.height),
              );
            }
            composer.toggleAiMode();
            await tester.pump();
            expect(scroll.position.extentBefore, closeTo(0, 1));
            await tester.pumpAndSettle();
            expect(scroll.position.extentBefore, closeTo(0, 1));
            expect(
              find.byKey(const ValueKey('chat-scroll-to-bottom')),
              findsNothing,
            );
            expect(tester.takeException(), isNull);
          },
        );
      }
    }
  }
}
