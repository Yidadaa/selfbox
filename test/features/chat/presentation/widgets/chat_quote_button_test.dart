import 'package:flutter_test/flutter_test.dart';
import 'package:selfbox/core/theme/sdk_material.dart';
import 'package:selfbox/features/chat/presentation/providers/chat_scroll_controller.dart';
import 'package:selfbox/features/chat/presentation/providers/composer_controller.dart';
import 'package:selfbox/gen/i18n/strings.g.dart';

import '../../../../support/app_widget_tester.dart';
import '../../../../support/fake_message_repository.dart';
import '../pages/chat_page_test_support.dart';

void main() {
  testWidgets('both actions fit beside active AI on a narrow screen', (
    tester,
  ) async {
    final messages = List.generate(40, (i) => testMessage(i + 1, 'note $i'));
    final container = await tester.pumpApp(
      messages: FakeMessageRepository(seed: messages),
    );
    tester.view.physicalSize = const Size(280 * 3, 650 * 3);
    final composer = container.read(composerControllerProvider.notifier);
    composer.quote(messages.first);
    composer.toggleAiMode();
    await tester.pumpAndSettle();
    container.read(chatScrollControllerProvider).jumpTo(200);
    await tester.pumpAndSettle();
    final quote = tester.getRect(find.byKey(const ValueKey('composer-quotes')));
    final bottom = tester.getRect(
      find.byKey(const ValueKey('chat-scroll-to-bottom')),
    );
    expect(quote.width, greaterThanOrEqualTo(48));
    expect(bottom.right, lessThan(quote.left));
    expect(
      quote.right,
      lessThan(tester.getRect(find.bySemanticsLabel(t.chat.aiMode)).left),
    );
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'quotes retain independent action away from bottom and restore full label',
    (tester) async {
      final messages = List.generate(
        40,
        (index) => testMessage(index + 1, 'note $index'),
      );
      final container = await tester.pumpApp(
        messages: FakeMessageRepository(seed: messages),
        locale: AppLocale.zhCn,
      );
      final composer = container.read(composerControllerProvider.notifier);
      composer.quote(messages.first);
      composer.quote(messages.last);
      await tester.pumpAndSettle();
      final quote = find.byKey(const ValueKey('composer-quotes'));
      final bottom = find.byKey(const ValueKey('chat-scroll-to-bottom'));
      expect(find.text('引用 2 条'), findsOneWidget);
      expect(bottom, findsNothing);
      final scroll = container.read(chatScrollControllerProvider);
      scroll.jumpTo(250);
      await tester.pumpAndSettle();
      expect(bottom, findsOneWidget);
      expect(quote, findsOneWidget);
      expect(
        find.descendant(of: quote, matching: find.text('2')),
        findsOneWidget,
      );
      expect(
        tester.getRect(bottom).right,
        lessThan(tester.getRect(quote).left),
      );
      await tester.tap(quote);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('quote-row-1')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('message-quotes-close')));
      await tester.pumpAndSettle();
      await tester.tap(bottom);
      await tester.pumpAndSettle();
      expect(find.text('引用 2 条'), findsOneWidget);
      expect(bottom, findsNothing);
      composer.removeQuote(messages.first.id);
      composer.removeQuote(messages.last.id);
      await tester.pumpAndSettle();
      expect(quote, findsNothing);
      scroll.jumpTo(200);
      await tester.pumpAndSettle();
      expect(bottom, findsOneWidget);
      expect(quote, findsNothing);
    },
  );
}
