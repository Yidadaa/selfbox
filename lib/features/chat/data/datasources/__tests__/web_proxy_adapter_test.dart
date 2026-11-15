import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:selfbox/features/chat/data/datasources/public_web_http.dart';
import 'package:selfbox/features/chat/data/datasources/web_proxy_adapter.dart';
import 'package:selfbox/features/chat/data/repositories/bing_web_research_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('system proxy discovery uses the requested URL', () async {
    const channel = MethodChannel('platform_proxy');
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(channel, (call) async {
      expect(call.method, 'getPlatformProxy');
      expect(call.arguments, {'url': 'https://example.com/page'});
      return '[{"type":"http","host":"127.0.0.1","port":"8888"}]';
    });
    addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
    expect(
      await resolveSystemWebProxy(Uri.parse('https://example.com/page')),
      'PROXY 127.0.0.1:8888',
    );
  });
  test(
    'real HTTP proxy receives the target without local target DNS',
    () => HttpOverrides.runWithHttpOverrides(() async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() => server.close(force: true));
      final subscription = server.listen((request) async {
        expect(request.uri.host, 'does-not-exist.example');
        expect(
          request.headers.value(HttpHeaders.userAgentHeader),
          'Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)',
        );
        expect(
          request.headers.value(HttpHeaders.acceptEncodingHeader),
          contains('gzip'),
        );
        request.response.headers.contentType = ContentType.html;
        request.response.headers.set(HttpHeaders.contentEncodingHeader, 'gzip');
        request.response.add(
          gzip.encode(
            '<title>Proxied page</title><main>proxied</main>'.codeUnits,
          ),
        );
        await request.response.close();
      });
      addTearDown(subscription.cancel);
      final client = createPublicWebDio(
        proxyResolver: (_) async => 'PROXY 127.0.0.1:${server.port}',
      );
      addTearDown(() => client.close(force: true));
      expect(
        (await BingWebResearchRepository(
          client,
        ).read('http://does-not-exist.example/page').run()).toNullable()?.title,
        'Proxied page',
      );
    }, _RealHttpOverrides()),
  );
  test(
    'direct mode bypasses the proxy resolver and blocks private destinations',
    () => HttpOverrides.runWithHttpOverrides(() async {
      final client = createPublicWebDio(
        direct: true,
        proxyResolver: (_) async {
          fail('Direct connections must not resolve a proxy');
        },
      );
      addTearDown(() => client.close(force: true));
      await expectLater(
        client.get<String>('http://127.0.0.1/'),
        throwsException,
      );
    }, _RealHttpOverrides()),
  );
}

class _RealHttpOverrides extends HttpOverrides {}
