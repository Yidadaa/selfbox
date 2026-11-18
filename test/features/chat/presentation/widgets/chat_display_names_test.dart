import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:selfbox/core/theme/sdk_material.dart';
import 'package:selfbox/features/chat/domain/models/message.dart';
import 'package:selfbox/features/chat/presentation/providers/composer_controller.dart';
import 'package:selfbox/features/chat/presentation/widgets/message_quote_sheet.dart';
import 'package:selfbox/features/settings/domain/models/user_profile.dart';
import 'package:selfbox/features/settings/presentation/providers/account_providers.dart';
import 'package:selfbox/gen/i18n/strings.g.dart';

import '../../../../support/app_widget_tester.dart';
import '../../../../support/fake_account_repository.dart';
import '../../../../support/fake_message_repository.dart';
import '../pages/chat_page_test_support.dart';

void main() {
  testWidgets('AI hint follows agent nickname and falls back when empty', (
    tester,
  ) async {
    final account = FakeAccountRepository()
      ..profile = const UserProfile(agentName: ' 云朵 ', nickname: '阿青');
    final container = await tester.pumpApp(
      account: account,
      locale: AppLocale.zhCn,
    );
    container.read(composerControllerProvider.notifier).toggleAiMode();
    await tester.pumpAndSettle();
    expect(find.text('给云朵发消息'), findsOneWidget);
    account.profile = const UserProfile(agentName: '星星');
    container.invalidate(userProfileProvider);
    await tester.pumpAndSettle();
    expect(find.text('给星星发消息'), findsOneWidget);
    account.profile = const UserProfile();
    container.invalidate(userProfileProvider);
    await tester.pumpAndSettle();
    expect(find.text('给小懒发消息'), findsOneWidget);
    container.read(composerControllerProvider.notifier).toggleAiMode();
    await tester.pumpAndSettle();
    expect(find.text(t.chat.inputHint), findsOneWidget);
  });

  for (final editable in [true, false]) {
    testWidgets('quote authors use both nicknames editable=$editable', (
      tester,
    ) async {
      final messages = [
        testMessage(1, 'user text'),
        testMessage(2, 'agent text', author: MessageAuthor.ai),
      ];
      final account = FakeAccountRepository()
        ..profile = const UserProfile(nickname: '阿青', agentName: '云朵');
      final container = await tester.pumpApp(
        account: account,
        messages: FakeMessageRepository(seed: messages),
        locale: AppLocale.zhCn,
      );
      for (final message in messages) {
        container.read(composerControllerProvider.notifier).quote(message);
      }
      final context = tester.element(find.byType(EditableText));
      if (editable) {
        unawaited(showQuoteEditor(context));
      } else {
        unawaited(showQuotedMessages(context, [1, 2]));
      }
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('quote-row-1')),
          matching: find.text('阿青'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('quote-row-2')),
          matching: find.text('云朵'),
        ),
        findsOneWidget,
      );
    });
  }
}
