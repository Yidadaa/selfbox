import 'package:flutter_test/flutter_test.dart';
import 'package:selfbox/features/chat/domain/models/message.dart';
import 'package:selfbox/features/settings/domain/models/user_profile.dart';
import 'package:selfbox/features/settings/presentation/providers/account_providers.dart';
import 'package:selfbox/gen/i18n/strings.g.dart';

import '../../../../support/app_widget_tester.dart';
import '../../../../support/fake_account_repository.dart';
import '../../../../support/fake_message_repository.dart';

void main() {
  for (final (locale, initial, renamed) in [
    (AppLocale.zhCn, '小云收起了 6 条讨论', '新名字收起了 6 条讨论'),
    (
      AppLocale.en,
      '小云 collapsed 6 discussion messages',
      '新名字 collapsed 6 discussion messages',
    ),
  ]) {
    testWidgets(
      'collapsed summary counts both authors and follows agent name in $locale',
      (tester) async {
        final account = FakeAccountRepository()
          ..profile = const UserProfile(agentName: ' 小云 ');
        final messages = FakeMessageRepository(
          seed: [
            for (var id = 1; id <= 6; id++)
              Message(
                id: id,
                createdAt: kTestNow,
                author: id.isEven ? MessageAuthor.ai : MessageAuthor.me,
                askedAi: id.isOdd,
                text: 'discussion $id',
              ),
          ],
        );
        final container = await tester.pumpApp(
          locale: locale,
          account: account,
          messages: messages,
        );
        expect(find.text(initial), findsOneWidget);
        expect(initial.endsWith('。'), isFalse);
        await account.save(const UserProfile(agentName: '新名字')).run();
        container.invalidate(userProfileProvider);
        await tester.pumpAndSettle();
        expect(find.text(renamed), findsOneWidget);
        await messages
            .add(const MessageDraft(author: MessageAuthor.ai, text: 'extra'))
            .run();
        await tester.pumpAndSettle();
        expect(find.text(renamed.replaceFirst('6', '7')), findsOneWidget);
        await messages.delete(7).run();
        await tester.pumpAndSettle();
        expect(find.text(renamed), findsOneWidget);
      },
    );
  }
}
