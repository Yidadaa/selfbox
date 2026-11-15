import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:selfbox/core/error/app_failure.dart';
import 'package:selfbox/features/chat/data/chat_data_providers.dart';
import 'package:selfbox/features/chat/data/repositories/objectbox_link_preview_repository.dart';
import 'package:selfbox/features/chat/presentation/providers/message_link_preview.dart';

import '../../../../support/fake_web_research_repository.dart';
import '../../../../support/temp_storage.dart';

void main() {
  test(
    'failed URLs retry independently and successful previews survive sessions',
    () async {
      final paths = createTempAppPaths();
      final store = await openTempStore(paths);
      final web = FakeWebResearchRepository()
        ..failure = const AppFailure.network(message: 'offline');
      final container = ProviderContainer(
        overrides: [
          linkPreviewRepositoryProvider.overrideWithValue(
            ObjectBoxLinkPreviewRepository(store, web),
          ),
        ],
      );
      final first = messageLinkPreviewProvider('https://example.com/first');
      final second = messageLinkPreviewProvider('https://example.com/second');
      expect((await container.read(first.future)).isLeft(), isTrue);
      web.failure = null;
      final results = await Future.wait([
        container.read(second.future),
        container.read(second.future),
      ]);
      expect(results.every((result) => result.isRight()), isTrue);
      container.invalidate(first);
      expect((await container.read(first.future)).isRight(), isTrue);
      expect(web.urls, [
        'https://example.com/first',
        'https://example.com/second',
        'https://example.com/first',
      ]);
      container.dispose();
      store.close();
      web.failure = const AppFailure.network(message: 'offline again');
      final reopened = ProviderContainer(
        overrides: [
          linkPreviewRepositoryProvider.overrideWithValue(
            ObjectBoxLinkPreviewRepository(await openTempStore(paths), web),
          ),
        ],
      );
      addTearDown(reopened.dispose);
      expect((await reopened.read(first.future)).isRight(), isTrue);
      expect((await reopened.read(second.future)).isRight(), isTrue);
      expect(web.urls, hasLength(3));
    },
  );
}
