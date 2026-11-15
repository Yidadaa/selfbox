import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:selfbox/features/chat/data/datasources/public_web_http.dart';

const _fixtures = 'test/features/chat/data/datasources/fixtures';

void main() {
  test(
    'desktop native fallback negotiates TLS and exposes redirects',
    () async {
      final serverContext = SecurityContext()
        ..useCertificateChain('$_fixtures/localhost-cert.pem')
        ..usePrivateKey('$_fixtures/localhost-key.pem');
      final server = await HttpServer.bindSecure(
        InternetAddress.loopbackIPv4,
        0,
        serverContext,
      );
      addTearDown(() => server.close(force: true));
      final paths = <String>[];
      final subscription = server.listen((request) async {
        paths.add(request.uri.path);
        if (request.uri.path == '/redirect') {
          request.response.statusCode = HttpStatus.found;
          request.response.headers.set(HttpHeaders.locationHeader, '/final');
        } else {
          request.response.headers.contentType = ContentType.text;
          request.response.headers.set(
            HttpHeaders.contentEncodingHeader,
            'gzip',
          );
          request.response.add(gzip.encode(utf8.encode('TLS page')));
        }
        await request.response.close();
      });
      addTearDown(subscription.cancel);
      await HttpOverrides.runWithHttpOverrides(() async {
        final dio = createPublicWebDio();
        addTearDown(() => dio.close(force: true));
        final response = await dio.get<ResponseBody>(
          'https://localhost:${server.port}/redirect',
          options: Options(
            followRedirects: false,
            validateStatus: (_) => true,
            responseType: ResponseType.stream,
          ),
          cancelToken: CancelToken(),
        );
        expect(response.statusCode, 302);
        expect(response.headers.value('location'), '/final');
        await response.data?.stream.drain<void>();
        expect(paths, ['/redirect']);
        expect(
          (await dio.get<String>('https://localhost:${server.port}/final'))
              .data,
          'TLS page',
        );
        expect(paths, ['/redirect', '/final']);
      }, _TrustedFixtureHttp());
    },
    skip: !Platform.isWindows && !Platform.isLinux,
  );
}

class _TrustedFixtureHttp extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) =>
      super.createHttpClient(
        context ??
            (SecurityContext()
              ..setTrustedCertificates('$_fixtures/localhost-cert.pem')),
      );
}
