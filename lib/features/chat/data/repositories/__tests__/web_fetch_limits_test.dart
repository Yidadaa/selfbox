import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:selfbox/features/chat/data/datasources/public_web_http.dart';
import 'package:selfbox/features/chat/data/repositories/bing_web_research_repository.dart';

void main() {
  for (final status in [301, 302, 303, 307, 308]) {
    test(
      'manually follows relative redirect $status through the same client',
      () async {
        final adapter = _Adapter(
          (options, _) => options.uri.path == '/start'
              ? ResponseBody.fromBytes(
                  [],
                  status,
                  headers: {
                    'location': ['/final'],
                  },
                )
              : _page(),
        );
        final dio = createPublicWebDio(adapter: adapter);
        addTearDown(() => dio.close(force: true));
        final page = (await BingWebResearchRepository(
          dio,
        ).read('https://example.com/start').run()).toNullable();
        expect(page?.url, 'https://example.com/final');
        expect(adapter.urls, [
          'https://example.com/start',
          'https://example.com/final',
        ]);
      },
    );
  }

  for (final redirects in [4, 5]) {
    test('allows four redirects and stops at five: $redirects', () async {
      var calls = 0;
      final adapter = _Adapter(
        (_, _) => calls++ < redirects
            ? ResponseBody.fromBytes(
                [],
                302,
                headers: {
                  'location': ['/next$calls'],
                },
              )
            : _page(),
      );
      final dio = createPublicWebDio(adapter: adapter);
      addTearDown(() => dio.close(force: true));
      final result = await BingWebResearchRepository(dio)
          .read('https://example.com/start')
          .run();
      expect(result.isRight(), redirects == 4);
      expect(adapter.urls, hasLength(5));
    });
  }

  for (final location in [null, 'http://10.0.0.1/', 'file:///secret']) {
    test('rejects missing or unsafe redirect $location', () async {
      final adapter = _Adapter(
        (_, _) => ResponseBody.fromBytes(
          [],
          302,
          headers: {
            if (location != null) 'location': [location],
          },
        ),
      );
      final dio = createPublicWebDio(adapter: adapter);
      addTearDown(() => dio.close(force: true));
      expect(
        (await BingWebResearchRepository(
          dio,
        ).read('https://example.com/start').run()).isLeft(),
        isTrue,
      );
      expect(adapter.urls, hasLength(1));
    });
  }

  test('search also blocks private redirects on its shared client', () async {
    final adapter = _Adapter(
      (_, _) => ResponseBody.fromBytes(
        [],
        302,
        headers: {
          'location': ['http://127.0.0.1/'],
        },
      ),
    );
    final dio = createPublicWebDio(adapter: adapter);
    addTearDown(() => dio.close(force: true));
    expect(
      (await BingWebResearchRepository(
        dio,
      ).search('dart', limit: 1).run()).isLeft(),
      isTrue,
    );
    expect(adapter.urls, hasLength(1));
  });

  test(
    'streamed size limit cancels the request without content length',
    () async {
      final cancelled = Completer<void>();
      final adapter = _Adapter((_, cancel) {
        unawaited(cancel?.then((_) => cancelled.complete()));
        return ResponseBody(
          Stream.fromIterable([
            Uint8List(BingWebResearchRepository.maxResponseBytes),
            Uint8List(1),
          ]),
          200,
          headers: {
            'content-type': ['text/plain'],
          },
        );
      });
      final dio = createPublicWebDio(adapter: adapter);
      addTearDown(() => dio.close(force: true));
      final result = await BingWebResearchRepository(dio)
          .read('https://example.com')
          .run();
      expect(result.getLeft().toNullable().toString(), contains('2 MB'));
      await cancelled.future.timeout(const Duration(seconds: 1));
    },
  );

  test('body timeout cancels transport and permits a later request', () async {
    final cancelled = Completer<void>();
    final body = StreamController<Uint8List>();
    var calls = 0;
    final adapter = _Adapter((_, cancel) {
      if (calls++ > 0) return _page();
      unawaited(cancel?.then((_) => cancelled.complete()));
      return ResponseBody(
        body.stream,
        200,
        headers: {
          'content-type': ['text/plain'],
        },
      );
    });
    final dio = createPublicWebDio(adapter: adapter);
    addTearDown(() => dio.close(force: true));
    addTearDown(body.close);
    final repository = BingWebResearchRepository(
      dio,
      requestTimeout: const Duration(milliseconds: 30),
    );
    expect(
      (await repository.read('https://example.com/first').run()).isLeft(),
      isTrue,
    );
    await cancelled.future.timeout(const Duration(seconds: 1));
    expect(
      (await repository.read('https://example.com/second').run()).isRight(),
      isTrue,
    );
  });
}

ResponseBody _page() => ResponseBody.fromString(
  '<title>Page</title><p>body</p>',
  200,
  headers: {
    'content-type': ['text/html'],
  },
);

class _Adapter implements HttpClientAdapter {
  _Adapter(this.respond);
  final ResponseBody Function(RequestOptions, Future<void>?) respond;
  final urls = <String>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    urls.add(options.uri.toString());
    expect(options.followRedirects, isFalse);
    expect(options.responseType, ResponseType.stream);
    expect(options.validateStatus(302), isTrue);
    expect(cancelFuture, isNotNull);
    return respond(options, cancelFuture);
  }

  @override
  void close({bool force = false}) {}
}
