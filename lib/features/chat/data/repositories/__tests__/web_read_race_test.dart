import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:selfbox/features/chat/data/repositories/bing_web_research_repository.dart';

void main() {
  for (final proxyWins in [true, false]) {
    test(
      'both routes start and first successful body wins, proxy=$proxyWins',
      () async {
        final direct = _Adapter();
        final proxy = _Adapter();
        final repository = BingWebResearchRepository(
          Dio()..httpClientAdapter = direct,
          proxyDio: Dio()..httpClientAdapter = proxy,
        );
        final result = repository.read('https://example.com/article').run();
        await Future.wait([direct.started.future, proxy.started.future]);
        final winner = proxyWins ? proxy : direct;
        final loser = proxyWins ? direct : proxy;
        winner.response.complete(_html());
        expect((await result).toNullable()?.title, 'Real article');
        await loser.cancelled.future;
        expect(loser.cancelled.isCompleted, isTrue);
        expect(
          winner.request?.headers['User-Agent'],
          'Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)',
        );
        expect(winner.request?.headers['Accept-Language'], contains('zh-CN'));
        expect(winner.request?.headers['Accept'], contains('text/html'));
        expect(winner.request?.headers['Accept-Encoding'], 'gzip');
      },
    );
  }
  test(
    'first failure waits for the other route; next request is independent',
    () async {
      final direct = _Adapter();
      final proxy = _Adapter();
      final repository = BingWebResearchRepository(
        Dio()..httpClientAdapter = direct,
        proxyDio: Dio()..httpClientAdapter = proxy,
      );
      final result = repository.read('https://example.com/first').run();
      await Future.wait([direct.started.future, proxy.started.future]);
      direct.response.complete(ResponseBody.fromString('Denied', 403));
      proxy.response.complete(_html());
      expect((await result).isRight(), isTrue);
      expect(
        (await repository.read('https://example.com/second').run()).isRight(),
        isTrue,
      );
    },
  );
  test('both failures return failure', () async {
    final direct = _Adapter()
      ..response.complete(ResponseBody.fromString('Denied', 403));
    final proxy = _Adapter()
      ..response.complete(ResponseBody.fromString('Down', 502));
    final repository = BingWebResearchRepository(
      Dio()..httpClientAdapter = direct,
      proxyDio: Dio()..httpClientAdapter = proxy,
    );
    expect(
      (await repository.read('https://example.com').run()).isLeft(),
      isTrue,
    );
  });
}

ResponseBody _html() => ResponseBody.fromString(
  '<title>Real article</title><main>Article body</main>',
  200,
  headers: {
    Headers.contentTypeHeader: ['text/html'],
  },
);

class _Adapter implements HttpClientAdapter {
  final started = Completer<void>();
  final cancelled = Completer<void>();
  final response = Completer<ResponseBody>();
  RequestOptions? request;
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) {
    if (request != null) return Future.value(_html());
    request = options;
    if (!started.isCompleted) started.complete();
    return Future.any([
      response.future,
      if (cancelFuture != null)
        cancelFuture.then<ResponseBody>((_) {
          if (!cancelled.isCompleted) cancelled.complete();
          throw DioException.requestCancelled(
            requestOptions: options,
            reason: 'cancelled',
          );
        }),
    ]);
  }

  @override
  void close({bool force = false}) {}
}
