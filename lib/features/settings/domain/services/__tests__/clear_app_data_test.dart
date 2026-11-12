import 'package:flutter_test/flutter_test.dart';
import 'package:selfbox/core/error/app_failure.dart';
import 'package:selfbox/core/testing/fake_account_repository.dart';
import 'package:selfbox/core/testing/fake_ai_settings.dart';
import 'package:selfbox/core/testing/fake_memory_repository.dart';
import 'package:selfbox/core/testing/fake_message_repository.dart';
import 'package:selfbox/features/chat/domain/models/message.dart';
import 'package:selfbox/features/settings/domain/models/user_profile.dart';

import 'package:selfbox/features/settings/domain/services/clear_app_data.dart';

void main() {
  test('clears every store and retries a partial failure', () async {
    final account = FakeAccountRepository()
      ..profile = const UserProfile(nickname: 'Me');
    final settings = FakeAiSettingsRepository(apiKeys: {'orphan': 'secret'});
    final messages = FakeMessageRepository();
    await messages
        .add(const MessageDraft(text: 'note', author: MessageAuthor.me))
        .run();
    final memory = FakeMemoryRepository(seed: {'user/test.md': 'memory'});
    final clear = ClearAppData(settings, messages, memory, account);
    account.failure = const AppFailure.database(message: 'disk');
    expect((await clear.run().run()).isLeft(), true);
    account.failure = null;
    expect((await clear.run().run()).isRight(), true);
    expect(settings.keys, isEmpty);
    expect(
      (await messages.latest(20).run()).getOrElse((e) => throw e),
      isEmpty,
    );
    expect((await memory.list().run()).getOrElse((e) => throw e), isEmpty);
    expect(account.profile, const UserProfile());
    expect((await clear.run().run()).isRight(), true);
  });
}
