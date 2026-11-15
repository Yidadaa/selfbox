import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:selfbox/core/error/app_failure.dart';
import 'package:selfbox/core/testing/fake_link_preview_repository.dart';
import 'package:selfbox/core/testing/fake_web_research_repository.dart';
import 'package:selfbox/features/chat/data/chat_data_providers.dart';
import 'package:selfbox/features/chat/presentation/providers/message_link_preview.dart';

void main() {
  test(
    'concurrent consumers share a fetch and failures can be retried',
    () async {
      final web = FakeWebResearchRepository();
      final container = ProviderContainer(
        overrides: [
          linkPreviewRepositoryProvider.overrideWithValue(
            FakeLinkPreviewRepository(web),
          ),
        ],
      );
      addTearDown(container.dispose);
      final provider = messageLinkPreviewProvider('https://example.com');
      final first = container.read(provider.future);
      final second = container.read(provider.future);
      expect((await first).toNullable()?.title, 'Example');
      await second;
      expect(web.urls, hasLength(1));
      web.failure = const AppFailure.network(message: 'offline');
      container.invalidate(provider);
      expect((await container.read(provider.future)).isLeft(), isTrue);
      web.failure = null;
      container.invalidate(provider);
      expect((await container.read(provider.future)).isRight(), isTrue);
    },
  );
}
