import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:selfbox/features/chat/data/repositories/bing_web_research_repository.dart';

void main() {
  test('Bing RSS search encodes query and parses results', () async {
    final calls = <Uri>[];
    final repository = BingWebResearchRepository(
      Dio()
        ..httpClientAdapter = _StubAdapter((request) {
          calls.add(Uri.parse(request.uri.toString()));
          return _response(
            200,
            'text/xml',
            '''<rss><channel><item><title>Flutter &amp; Dart</title><link>https://dart.dev/</link><description>Official &lt;b&gt;site&lt;/b&gt;</description></item></channel></rss>''',
          );
        }),
    );
    final hits = (await repository.search('Flutter 中文', limit: 5).run())
        .toNullable();
    expect(calls.single.queryParameters['q'], 'Flutter 中文');
    expect(calls.single.queryParameters['format'], 'rss');
    expect(hits?.single.title, 'Flutter & Dart');
    expect(hits?.single.url, 'https://dart.dev/');
    expect(hits?.single.snippet, 'Official site');
  });

  test('read extracts article text and rejects local destinations', () async {
    final calls = <Uri>[];
    final repository = BingWebResearchRepository(
      Dio()
        ..httpClientAdapter = _StubAdapter((request) {
          calls.add(request.uri);
          return _response(
            200,
            'text/html',
            '''<html><head><title>Article</title></head><body><nav>Ignore navigation</nav><main><h1>Hello</h1><p>Useful page content.</p><script>Ignore script</script></main></body></html>''',
          );
        }),
    );
    final page = (await repository.read('https://example.com/story').run())
        .toNullable();
    expect(page?.title, 'Article');
    expect(page?.text, contains('Useful page content.'));
    expect(page?.text, isNot(contains('Ignore navigation')));
    expect(page?.text, isNot(contains('Ignore script')));
    expect(
      (await repository.read('http://127.0.0.1/private').run()).isLeft(),
      isTrue,
    );
    expect(calls, hasLength(1));
  });

  test(
    'search rejects empty input and surfaces upstream HTTP failures',
    () async {
      var calls = 0;
      final repository = BingWebResearchRepository(
        Dio()
          ..httpClientAdapter = _StubAdapter((request) {
            calls++;
            return _response(503, 'text/plain', 'Unavailable');
          }),
      );
      expect((await repository.search('', limit: 5).run()).isLeft(), isTrue);
      expect(calls, 0);
      final failed = (await repository.search('dart', limit: 5).run())
          .getLeft()
          .toNullable();
      expect(failed?.toString(), contains('503'));
    },
  );

  test(
    'read blocks redirect to private address and oversized response',
    () async {
      var calls = 0;
      final redirecting = BingWebResearchRepository(
        Dio()
          ..httpClientAdapter = _StubAdapter((request) {
            calls++;
            return ResponseBody.fromBytes(
              const [],
              302,
              headers: {
                'location': ['http://127.0.0.1/admin'],
              },
            );
          }),
      );
      expect(
        (await redirecting.read('https://example.com').run()).isLeft(),
        isTrue,
      );
      expect(calls, 1);
      final oversized = BingWebResearchRepository(
        Dio()
          ..httpClientAdapter = _StubAdapter(
            (request) => ResponseBody.fromBytes(
              const [],
              200,
              headers: {
                Headers.contentTypeHeader: ['text/html'],
                Headers.contentLengthHeader: [
                  '${BingWebResearchRepository.maxResponseBytes + 1}',
                ],
              },
            ),
          ),
      );
      expect(
        (await oversized.read('https://example.com').run()).isLeft(),
        isTrue,
      );
    },
  );

  test(
    'read excludes scripts, truncates long bodies and rejects binary',
    () async {
      final html =
          '<main><p>${'word ' * 20000}</p><script>hidden</script></main>';
      final repository = BingWebResearchRepository(
        Dio()
          ..httpClientAdapter = _StubAdapter(
            (request) => _response(200, 'text/html', html),
          ),
      );
      final page = (await repository.read('https://example.com').run())
          .toNullable();
      expect(page?.text.length, lessThanOrEqualTo(80000));
      expect(page?.truncated, isTrue);
      expect(page?.text, isNot(contains('hidden')));
      final binary = BingWebResearchRepository(
        Dio()
          ..httpClientAdapter = _StubAdapter(
            (request) => _response(200, 'application/pdf', 'pdf'),
          ),
      );
      expect(
        (await binary.read('https://example.com/file.pdf').run()).isLeft(),
        isTrue,
      );
    },
  );

  test('request timeout stops a stalled HTTP response', () async {
    final repository = BingWebResearchRepository(
      Dio()..httpClientAdapter = _StalledAdapter(),
      requestTimeout: const Duration(milliseconds: 25),
    );
    final result = await repository.search('dart', limit: 5).run();
    expect(result.isLeft(), isTrue);
    expect(result.getLeft().toNullable().toString(), contains('timed out'));
  });
  test('a timed-out page does not cancel the next URL request', () async {
    final adapter = _TimeoutThenSuccessAdapter();
    final repository = BingWebResearchRepository(
      Dio()..httpClientAdapter = adapter,
      requestTimeout: const Duration(milliseconds: 25),
    );
    expect(
      (await repository.read('https://example.com/first').run()).isLeft(),
      isTrue,
    );
    expect(
      (await repository.read('https://example.com/second').run())
          .toNullable()
          ?.title,
      'Second',
    );
    expect(adapter.urls, [
      'https://example.com/first',
      'https://example.com/second',
    ]);
  });
}

class _TimeoutThenSuccessAdapter implements HttpClientAdapter {
  final urls = <String>[];
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    urls.add(options.uri.toString());
    if (urls.length == 1) {
      await cancelFuture;
      throw DioException.requestCancelled(
        requestOptions: options,
        reason: 'timeout',
      );
    }
    return _response(
      200,
      'text/html',
      '<title>Second</title><p>Page content</p>',
    );
  }

  @override
  void close({bool force = false}) {}
}

class _StubAdapter implements HttpClientAdapter {
  _StubAdapter(this.respond);
  final ResponseBody Function(RequestOptions request) respond;
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async => respond(options);
  @override
  void close({bool force = false}) {}
}

class _StalledAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    await cancelFuture;
    throw DioException(requestOptions: options, type: DioExceptionType.cancel);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _response(int status, String contentType, String body) =>
    ResponseBody.fromBytes(
      utf8.encode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [contentType],
      },
    );
