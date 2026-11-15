import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:selfbox/core/router/app_router.dart';
import 'package:selfbox/core/testing/app_widget_tester.dart';
import 'package:selfbox/core/testing/fake_message_repository.dart';
import 'package:selfbox/core/theme/app_icons.dart';
import 'package:selfbox/core/widgets/app_action_button.dart';
import 'package:selfbox/core/widgets/app_page_scaffold.dart';
import 'package:selfbox/features/chat/presentation/providers/composer_controller.dart';
import 'package:selfbox/gen/i18n/strings.g.dart';

import 'chat_page_test_support.dart';

void main() {
  testWidgets('quote controls fit a narrow keyboard viewport and use Quotes', (
    tester,
  ) async {
    final original = testMessage(1, 'keep this original');
    final container = await tester.pumpApp(
      messages: FakeMessageRepository(seed: [original]),
    );
    container.read(composerControllerProvider.notifier).quote(original);
    await tester.pumpAndSettle();
    tester.view.physicalSize = const Size(280 * 3, 500 * 3);
    await tester.enterText(composerField(), 'line one\nline two');
    tester.view.viewInsets = const FakeViewPadding(bottom: 240 * 3);
    await tester.pumpAndSettle();
    final quote = tester.getRect(find.byKey(const ValueKey('composer-quotes')));
    final toggle = tester.getRect(find.bySemanticsLabel(t.chat.aiMode));
    expect(quote.right, lessThan(toggle.left));
    expect(quote.center.dy, closeTo(toggle.center.dy, 0.1));
    await tester.tap(find.byKey(const ValueKey('composer-quotes')));
    await tester.pumpAndSettle();
    final remove = find.byKey(const ValueKey('remove-quote-1'));
    expect(tester.getRect(remove).bottom, lessThanOrEqualTo(260));
    expect(tester.widget<AppActionIconButton>(remove).icon, AppIcons.delete);
    await tester.tap(remove);
    await tester.pumpAndSettle();
    expect(find.byType(BottomSheet), findsNothing);
    expect(find.byKey(const ValueKey('composer-quotes')), findsNothing);
    expect(container.read(appRouterProvider).state.matchedLocation, '/chat');
    container.read(composerControllerProvider.notifier).quote(original);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('composer-quotes')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('quote-row-1')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('long press accumulates quotes and sheet removes immediately', (
    tester,
  ) async {
    final messages = FakeMessageRepository(
      seed: [
        testMessage(1, 'first original'),
        testMessage(2, 'second original'),
      ],
    );
    final container = await tester.pumpApp(
      messages: messages,
      locale: AppLocale.zhCn,
    );
    for (final text in ['first original', 'second original']) {
      await tester.longPress(find.text(text));
      await tester.pumpAndSettle();
      await tester.tap(find.text(t.common.quote));
      await tester.pumpAndSettle();
    }
    expect(find.text('引用 2 条'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('composer-quotes')));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel(t.chat.send).hitTestable(), findsNothing);
    await tester.tap(find.byKey(const ValueKey('remove-quote-1')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('quote-row-1')), findsNothing);
    expect(find.byType(BottomSheet), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('message-quotes-close')));
    await tester.pumpAndSettle();
    await tester.enterText(composerField(), 'new reply');
    await tester.pump();
    await tester.tap(find.bySemanticsLabel(t.chat.send));
    await tester.pumpAndSettle();
    expect(messages.added.single.quotedMessageIds, [2]);
    expect(find.text('引用了 1 条消息'), findsOneWidget);
    expect(find.byKey(const ValueKey('composer-quotes')), findsNothing);
    await tester.tap(find.text('引用了 1 条消息'));
    await tester.pumpAndSettle();
    expect(
      container.read(appRouterProvider).state.matchedLocation,
      '/chat/at/2',
    );
    expect(find.byKey(const ValueKey('located-2')), findsOneWidget);
    expect(find.text('first original'), findsNothing);
    expect(find.text('new reply'), findsNothing);
    expect(find.byType(BottomSheet), findsNothing);
  });

  testWidgets(
    'multiple references open a picker and locate an unloaded old message',
    (tester) async {
      final messages = FakeMessageRepository(
        seed: [
          for (var id = 1; id <= 90; id++) testMessage(id, 'original $id'),
          testMessage(100, 'reply').copyWith(quotedMessageIds: [1, 2]),
        ],
      );
      final container = await tester.pumpApp(messages: messages);
      expect(find.text('original 1'), findsNothing);
      await tester.tap(find.text(t.chat.quotedCount(count: 2)));
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsOneWidget);
      expect(find.byKey(const ValueKey('quote-row-2')), findsOneWidget);
      expect(find.byKey(const ValueKey('quote-row-3')), findsNothing);
      await tester.tap(find.byKey(const ValueKey('quote-row-1')));
      await tester.pumpAndSettle();
      expect(
        container.read(appRouterProvider).state.matchedLocation,
        '/chat/at/1',
      );
      expect(find.byKey(const ValueKey('located-1')), findsOneWidget);
      expect(find.text('original 2'), findsNothing);
      expect(find.text('reply'), findsNothing);
      final list = find.byKey(const ValueKey('message-location-1'));
      expect(tester.getRect(list).top, 0);
      final target = tester.getRect(find.byKey(const ValueKey('located-1')));
      expect(target.top, AppPageInsets.of(tester.element(list)).top);
      expect(target.bottom, lessThan(kPhoneViewport.height));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('referenced message scrolls beneath the floating header', (
    tester,
  ) async {
    final container = await tester.pumpApp(
      messages: FakeMessageRepository(
        seed: [
          testMessage(
            1,
            List.filled(50, 'long original paragraph').join('\n\n'),
          ),
          testMessage(2, 'unrelated neighbor'),
        ],
      ),
    );
    container.read(appRouterProvider).go('/chat/at/1');
    await tester.pumpAndSettle();
    final list = find.byKey(const ValueKey('message-location-1'));
    final row = find.byKey(const ValueKey('located-1'));
    final before = tester.getRect(row).top;
    await tester.drag(list, const Offset(0, -120));
    await tester.pumpAndSettle();
    expect(tester.getRect(list).top, 0);
    expect(tester.getRect(row).top, lessThan(before));
    expect(tester.getRect(row).top, lessThan(47));
    expect(find.bySemanticsLabel(t.common.close).hitTestable(), findsOneWidget);
    expect(find.text('unrelated neighbor'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('deleted references remain identifiable and removable', (
    tester,
  ) async {
    final original = testMessage(1, 'removed original');
    final messages = FakeMessageRepository(
      seed: [
        original,
        testMessage(2, 'reply').copyWith(quotedMessageIds: [1]),
      ],
    );
    final container = await tester.pumpApp(messages: messages);
    container.read(composerControllerProvider.notifier).quote(original);
    await messages.delete(1).run();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('composer-quotes')));
    await tester.pumpAndSettle();
    expect(find.text(t.chat.messageMissing), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('remove-quote-1')));
    await tester.pumpAndSettle();
    expect(find.byType(BottomSheet), findsNothing);
    await tester.tap(find.text(t.chat.quotedCount(count: 1)));
    await tester.pumpAndSettle();
    expect(find.text(t.chat.messageMissing), findsOneWidget);
  });
}
