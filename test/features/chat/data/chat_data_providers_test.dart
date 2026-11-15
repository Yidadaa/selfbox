import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:selfbox/features/chat/data/chat_data_providers.dart';
import 'package:selfbox/features/chat/data/repositories/bing_web_research_repository.dart';

void main() {
  test(
    'web provider shares one client for search/read and closes it',
    () async {
      final container = ProviderContainer();
      final repository = container.read(
        webResearchRepositoryProvider,
      ) as BingWebResearchRepository;
      final adapter = _Adapter();
      repository.dio.httpClientAdapter.close(force: true);
      repository.dio.httpClientAdapter = adapter;
      expect(
        (await repository.search('dart', limit: 1).run()).isRight(),
        isTrue,
      );
      expect(
        (await repository.read('https://example.com').run()).isRight(),
        isTrue,
      );
      expect(adapter.hosts, ['www.bing.com', 'example.com']);
      container.dispose();
      expect(adapter.forcedClosed, isTrue);
    },
  );
}

class _Adapter implements HttpClientAdapter {
  final hosts = <String>[];
  bool forcedClosed = false;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    hosts.add(options.uri.host);
    return options.uri.host == 'www.bing.com'
        ? ResponseBody.fromString(
            '<rss><channel></channel></rss>',
            200,
            headers: {
              'content-type': ['application/rss+xml'],
            },
          )
        : ResponseBody.fromString(
            '<title>Page</title><p>body</p>',
            200,
            headers: {
              'content-type': ['text/html'],
            },
          );
  }

  @override
  void close({bool force = false}) => forcedClosed = force;
}
