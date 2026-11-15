import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:native_dio_adapter/native_dio_adapter.dart';
import 'package:selfbox/features/chat/data/datasources/public_web_http.dart';

void main() {
  test('native factory uses the standard IO fallback on desktop', () {
    final dio = createPublicWebDio();
    addTearDown(() => dio.close(force: true));
    expect(dio.options.connectTimeout, const Duration(seconds: 10));
    expect(dio.httpClientAdapter, isA<NativeAdapter>());
    if (Platform.isWindows || Platform.isLinux) {
      expect(
        (dio.httpClientAdapter as NativeAdapter).adapter,
        isA<IOHttpClientAdapter>(),
      );
    }
  });

  test('injected adapter receives requests and forced close', () async {
    final adapter = _Adapter();
    final dio = createPublicWebDio(adapter: adapter);
    expect((await dio.get<String>('https://example.com')).data, 'ok');
    dio.close(force: true);
    expect(adapter.closed, isTrue);
  });

  test('only public HTTP destinations are accepted', () {
    for (final url in [
      'https://example.com/news',
      'http://www.bing.com/search',
    ]) {
      expect(isPublicWebUri(Uri.parse(url)), isTrue, reason: url);
    }
    for (final url in [
      'file:///etc/passwd',
      'http://localhost/',
      'http://127.0.0.1/',
      'http://192.168.1.2/',
      'http://10.1.2.3/',
      'http://169.254.169.254/',
      'http://example.local/',
      'https://user:pass@example.com/',
      'https://example.com:8080/',
      'https://example.invalid/',
    ]) {
      expect(isPublicWebUri(Uri.parse(url)), isFalse, reason: url);
    }
    expect(isPublicWebAddress(InternetAddress('8.8.8.8')), isTrue);
    expect(isPublicWebAddress(InternetAddress('::1')), isFalse);
    expect(isPublicWebAddress(InternetAddress('fc00::1')), isFalse);
  });
}

class _Adapter implements HttpClientAdapter {
  bool closed = false;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async => ResponseBody.fromString('ok', 200);

  @override
  void close({bool force = false}) => closed = force;
}
