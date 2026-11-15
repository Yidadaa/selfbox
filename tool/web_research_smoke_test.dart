import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:selfbox/core/database/app_store.dart';
import 'package:selfbox/core/testing/temp_storage.dart';
import 'package:selfbox/features/chat/data/datasources/public_web_http.dart';
import 'package:selfbox/features/chat/data/repositories/bing_web_research_repository.dart';
import 'package:selfbox/features/chat/presentation/providers/message_link_preview.dart';
import 'package:talker_flutter/talker_flutter.dart';

void main() {
  for (final url in [
    'https://example.com',
    'https://dart.dev/overview',
    'https://www.baidu.com',
  ]) {
    test('live page $url', () async {
      final dio = createPublicWebDio();
      addTearDown(() => dio.close(force: true));
      final talker = Talker();
      final repository = BingWebResearchRepository(
        dio,
        onFailure: (error, stack) =>
            talker.error('Live page failure', error, stack),
      );
      final result = await repository.read(url).run();
      expect(
        result.isRight(),
        isTrue,
        reason: '${result.getLeft().toNullable()}',
      );
      expect(result.toNullable()?.title, isNotEmpty);
      expect(result.toNullable()?.text, isNotEmpty);
      talker.info(
        'Read $url: ${result.toNullable()?.title}, ${result.toNullable()?.text.length} characters',
      );
    });
  }
  test('live page production providers and ObjectBox', () async {
    final container = ProviderContainer(
      overrides: [appStoreProvider.overrideWithValue(await openTempStore())],
    );
    addTearDown(container.dispose);
    for (final url in [
      'https://example.com',
      'https://dart.dev/overview',
      'https://www.baidu.com',
    ]) {
      final result = await container.read(
        messageLinkPreviewProvider(url).future,
      );
      expect(
        result.isRight(),
        isTrue,
        reason: '$url: ${result.getLeft().toNullable()}',
      );
      expect(result.toNullable()?.title, isNotEmpty);
      Talker().info('Persisted $url: ${result.toNullable()?.title}');
    }
  });
  test('live Bing RSS and HTTP page reading', () async {
    final dio = createPublicWebDio();
    addTearDown(() => dio.close(force: true));
    final repository = BingWebResearchRepository(dio);
    final search = await repository.search('flutter.dev', limit: 3).run();
    expect(
      search.isRight(),
      isTrue,
      reason: '${search.getLeft().toNullable()}',
    );
    final hits = search.toNullable() ?? const [];
    expect(hits, isNotEmpty);
    final page = await repository.read('https://dart.dev/overview').run();
    expect(page.isRight(), isTrue, reason: '${page.getLeft().toNullable()}');
    final text = page.toNullable()?.text ?? '';
    expect(text, isNotEmpty);
    expect(text, isNot(contains('<html')));
  });
}
