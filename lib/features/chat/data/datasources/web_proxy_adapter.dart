import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:platform_proxy/platform_proxy.dart';

typedef WebProxyResolver = Future<String> Function(Uri uri);

Future<String> resolveSystemWebProxy(Uri uri) =>
    TaskEither.tryCatch(
          () async =>
              (await PlatformProxy()
                      .getPlatformProxies(url: uri.toString())
                      .timeout(const Duration(seconds: 3)))
                  .getProxiesAsPac(),
          (Object error, StackTrace stack) => error,
        )
        .match(
          (_) => _environmentProxy(uri),
          (proxy) => proxy.isEmpty ? _environmentProxy(uri) : proxy,
        )
        .run();

String _environmentProxy(Uri uri) => HttpClient.findProxyFromEnvironment(
  uri,
  environment: {
    for (final entry in Platform.environment.entries)
      entry.key.toLowerCase(): entry.value,
  },
);

class WebProxyAdapter implements HttpClientAdapter {
  WebProxyAdapter({required this.resolve, required this.createAdapter});
  final WebProxyResolver resolve;
  final HttpClientAdapter Function(String proxy) createAdapter;
  final _active = <HttpClientAdapter>{};
  bool _closed = false;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final proxy = await resolve(options.uri)
        .timeout(const Duration(seconds: 3));
    if (_closed || options.cancelToken?.isCancelled == true) {
      throw DioException.requestCancelled(
        requestOptions: options,
        reason: 'Request cancelled',
      );
    }
    final adapter = createAdapter(proxy);
    _active.add(adapter);
    unawaited(cancelFuture?.whenComplete(() => _release(adapter)));
    try {
      final response = await adapter.fetch(
        options,
        requestStream,
        cancelFuture,
      );
      final stream = response.stream;
      response.stream = _releaseAfter(stream, adapter);
      return response;
    } catch (_) {
      _release(adapter);
      rethrow;
    }
  }

  Stream<Uint8List> _releaseAfter(
    Stream<Uint8List> stream,
    HttpClientAdapter adapter,
  ) async* {
    try {
      yield* stream;
    } finally {
      _release(adapter);
    }
  }

  void _release(HttpClientAdapter adapter) {
    if (_active.remove(adapter)) adapter.close(force: true);
  }

  @override
  void close({bool force = false}) {
    _closed = true;
    for (final adapter in _active.toList()) {
      _release(adapter);
    }
  }
}
