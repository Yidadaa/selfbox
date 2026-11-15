import 'package:selfbox/core/router/app_router.dart';
import 'package:selfbox/features/chat/presentation/widgets/__tests__/chat_background_test.dart'
    as chat_background;
import 'package:selfbox/features/memory/presentation/pages/__tests__/memory_floating_button_test.dart'
    as memory_floating;
import 'package:selfbox/features/settings/domain/models/app_preferences.dart';
import 'package:selfbox/features/settings/presentation/pages/__tests__/settings_automatic_test.dart'
    as settings_automatic;

import 'features/chat/presentation/pages/chat_page_test_support.dart';
import 'support/app_widget_tester.dart';
import 'support/fake_memory_repository.dart';
import 'support/fake_message_repository.dart';

void main() {
  memory_floating.registerTests((tester, quality) async {
    final container = await tester.pumpApp(
      memory: FakeMemoryRepository(
        seed: {
          for (var index = 0; index < 24; index++)
            'notes/note$index.md': '# Note $index',
        },
      ),
      initialPreferences: AppPreferences(renderQuality: quality),
    );
    container.read(appRouterProvider).go('/memory');
    await tester.pumpAndSettle();
  });
  chat_background.registerTests(
    pumpChat: (tester) => tester.pumpApp(
      messages: FakeMessageRepository(
        seed: [for (var id = 1; id <= 40; id++) testMessage(id, 'Note $id')],
      ),
    ),
    pumpPage: (tester, page) async {
      await tester.pumpPage(page);
    },
  );
  settings_automatic.registerTests(
    (tester, repository, initial) =>
        tester.pumpApp(preferences: repository, initialPreferences: initial),
  );
}
