import 'package:flutter_test/flutter_test.dart';
import 'package:selfbox/core/theme/sdk_material.dart';
import 'package:selfbox/core/widgets/app_action_popover.dart';
import 'package:selfbox/features/chat/domain/models/message.dart';
import 'package:selfbox/features/chat/presentation/widgets/message_preview.dart';
import 'package:selfbox/gen/i18n/strings.g.dart';

import '../../../../support/app_widget_tester.dart';
import '../../../../support/fake_message_repository.dart';
import 'chat_page_test_support.dart';

void main() {
  testWidgets(
    'long press pins; outside taps preserve panel; close retains pins',
    (tester) async {
      final repo = FakeMessageRepository(seed: [testMessage(1, 'keep me')]);
      await tester.pumpApp(messages: repo, locale: AppLocale.zhCn);
      await tester.longPress(find.text('keep me'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('钉住消息'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('pinned-bubble')), findsOneWidget);
      expect(find.text('置顶 1 条'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('pinned-bubble')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('pinned-panel')), findsOneWidget);
      await tester.tapAt(const Offset(200, 610));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('pinned-panel')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('close-pins')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('pinned-panel')), findsNothing);
      expect((await repo.watchPinned().first).single.text, 'keep me');
    },
  );

  testWidgets(
    'AI stays full; removing last pin closes panel and hides button',
    (tester) async {
      final repo = FakeMessageRepository(
        seed: [testMessage(1, 'AI full', author: MessageAuthor.ai)],
      );
      await repo.setPinned(1, pinned: true).run();
      await tester.pumpApp(messages: repo);
      await tester.tap(find.byKey(const ValueKey('pinned-bubble')));
      await tester.pumpAndSettle();
      final panel = find.byKey(const ValueKey('pinned-panel'));
      final preview = find.descendant(
        of: panel,
        matching: find.byType(MessagePreview),
      );
      expect(tester.widget<MessagePreview>(preview).enabled, false);
      await tester.longPress(
        find.descendant(
          of: panel,
          matching: find.text('AI full', findRichText: true),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<AppActionPopover>(find.byType(AppActionPopover))
            .actions
            .length,
        1,
      );
      await tester.tap(find.text('Unpin'));
      await tester.pumpAndSettle();
      expect(panel, findsNothing);
      expect(find.byKey(const ValueKey('pinned-bubble')), findsNothing);
      expect((await repo.latest(10).run()).toNullable()?.length, 1);
      await repo.setPinned(1, pinned: true).run();
      await tester.pumpAndSettle();
      expect(panel, findsNothing);
      expect(find.byKey(const ValueKey('pinned-bubble')), findsOneWidget);
    },
  );

  testWidgets(
    'clear requires confirmation and keyboard bounds leave controls free',
    (tester) async {
      final repo = FakeMessageRepository(
        seed: List.generate(12, (i) => testMessage(i + 1, 'message $i')),
      );
      for (var id = 1; id <= 12; id++) {
        await repo.setPinned(id, pinned: true).run();
      }
      await tester.pumpApp(messages: repo);
      await tester.tap(find.byKey(const ValueKey('pinned-bubble')));
      await tester.pumpAndSettle();
      final panel = find.byKey(const ValueKey('pinned-panel'));
      expect(tester.getSize(panel).height, lessThanOrEqualTo(844 / 2));
      await tester.tap(composerField());
      tester.view.viewInsets = const FakeViewPadding(bottom: 300 * 3);
      await tester.pumpAndSettle();
      expect(
        tester.getRect(panel).bottom,
        lessThan(tester.getRect(composerField()).top),
      );
      expect(tester.getRect(panel).top, greaterThanOrEqualTo(47 + 80));
      await tester.tap(find.byKey(const ValueKey('clear-pins')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect((await repo.watchPinned().first).length, 12);
      await tester.tap(find.byKey(const ValueKey('clear-pins')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Clear'));
      await tester.pumpAndSettle();
      expect(await repo.watchPinned().first, isEmpty);
      expect(panel, findsNothing);
      expect(find.byKey(const ValueKey('pinned-bubble')), findsNothing);
      expect((await repo.latest(20).run()).toNullable()?.length, 12);
    },
  );
}
