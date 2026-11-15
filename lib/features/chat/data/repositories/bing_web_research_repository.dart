import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/error/app_failure.dart';
import '../../domain/repositories/web_research_repository.dart';
import '../datasources/public_web_http.dart';
import '../datasources/web_content_parser.dart';
import 'web_read_race.dart';

class BingWebResearchRepository implements WebResearchRepository {
  const BingWebResearchRepository(
    this.dio, {
    this.requestTimeout = const Duration(seconds: 20),
    this.onFailure,
    this.proxyDio,
  });
  final Dio dio;
  final Dio? proxyDio;
  final Duration requestTimeout;
  final void Function(Object, StackTrace)? onFailure;
  static const maxResponseBytes = 2 * 1024 * 1024;

  @override
  TaskEither<AppFailure, List<WebSearchHit>> search(
    String query, {
    required int limit,
  }) => TaskEither.tryCatch(() async {
    if (query.trim().isEmpty || query.length > 500) {
      throw const AppFailure.validation(
        message: 'Search query must contain 1–500 characters',
      );
    }
    final uri = Uri.https('www.bing.com', '/search', {
      'q': query.trim(),
      'format': 'rss',
      'count': '${limit.clamp(1, 10)}',
    });
    final response = await _fetch(uri);
    return compute(_parseSearch, (response.text, limit.clamp(1, 10)));
  }, _failure);

  @override
  TaskEither<AppFailure, WebPageContent> read(String url) => TaskEither(
    () => raceWebReads([
      dio,
      ?proxyDio,
    ], (client, cancel) => _readPage(url, client, cancel).run()),
  );

  TaskEither<AppFailure, WebPageContent> _readPage(
    String url,
    Dio client,
    CancelToken cancel,
  ) => TaskEither.tryCatch(() async {
    final uri = Uri.tryParse(url);
    if (uri == null || url.length > 4096 || !isPublicWebUri(uri)) {
      throw const AppFailure.validation(
        message: 'Provide a public HTTP or HTTPS page URL',
      );
    }
    final response = await _fetch(uri, client: client, cancelToken: cancel);
    if (!{
      'text/html',
      'application/xhtml+xml',
      'text/plain',
    }.contains(response.contentType)) {
      throw const AppFailure.validation(
        message: 'Only HTML and plain text pages can be read',
      );
    }
    return compute(_parsePage, (
      response.text,
      response.url,
      response.contentType,
    ));
  }, _failure);

  Future<({String text, String url, String contentType})> _fetch(
    Uri uri, {
    Dio? client,
    CancelToken? cancelToken,
  }) async {
    final cancel = cancelToken ?? CancelToken();
    final timer = Timer(
      requestTimeout,
      () => cancel.cancel('Web request timed out'),
    );
    try {
      var current = uri;
      for (var redirects = 0; redirects <= 4; redirects++) {
        if (!isPublicWebUri(current)) {
          throw const AppFailure.validation(
            message: 'Redirect to a private or unsupported URL',
          );
        }
        final response = await (client ?? dio).getUri<ResponseBody>(
          current,
          cancelToken: cancel,
          options: Options(
            responseType: ResponseType.stream,
            followRedirects: false,
            receiveTimeout: requestTimeout,
            validateStatus: (_) => true,
            headers: {
              'User-Agent': 'Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)',
              'Accept': 'text/html,application/xhtml+xml,application/rss+xml,application/xml,text/plain;q=0.9,*/*;q=0.1',
              'Accept-Language': 'zh-CN,zh;q=0.9,en;q=0.8',
              'Accept-Encoding': 'gzip',
            },
          ),
        );
        final body = response.data;
        if (body == null) {
          throw const AppFailure.network(message: 'Empty HTTP response');
        }
        final status = response.statusCode ?? 0;
        if ({301, 302, 303, 307, 308}.contains(status)) {
          await body.stream.listen((_) {}).cancel();
          final location = response.headers.value('location');
          if (location == null) {
            throw const AppFailure.network(
              message: 'Redirect has no destination',
            );
          }
          current = current.resolve(location);
          continue;
        }
        if (status < 200 || status >= 300) {
          await body.stream.listen((_) {}).cancel();
          throw AppFailure.network(
            message: 'Page request failed (HTTP $status)',
            statusCode: status,
          );
        }
        final declared = int.tryParse(
          response.headers.value('content-length') ?? '',
        );
        if (declared != null && declared > maxResponseBytes) {
          cancel.cancel('Page too large');
          throw const AppFailure.validation(
            message: 'Page exceeds the 2 MB download limit',
          );
        }
        final bytes = BytesBuilder(copy: false);
        await for (final chunk in body.stream.timeout(requestTimeout)) {
          if (bytes.length + chunk.length > maxResponseBytes) {
            cancel.cancel('Page too large');
            throw const AppFailure.validation(
              message: 'Page exceeds the 2 MB download limit',
            );
          }
          bytes.add(chunk);
        }
        final contentType = (response.headers.value('content-type') ?? '')
            .toLowerCase();
        final text = contentType.contains('iso-8859-1')
            ? latin1.decode(bytes.takeBytes())
            : utf8.decode(bytes.takeBytes(), allowMalformed: true);
        return (
          text: text,
          url: current.toString(),
          contentType: contentType.split(';').first.trim(),
        );
      }
      throw const AppFailure.network(message: 'Too many redirects');
    } finally {
      timer.cancel();
    }
  }

  AppFailure _failure(Object error, StackTrace stack) {
    if (error is! DioException || !CancelToken.isCancel(error)) {
      onFailure?.call(error, stack);
    }
    return switch (error) {
      final AppFailure failure => failure,
      DioException() || TimeoutException() => const AppFailure.network(
        message: 'Unable to reach the website; it may be unavailable or the request timed out',
      ),
      _ => const AppFailure.network(
        message: 'Unable to parse the website response',
      ),
    };
  }
}

List<WebSearchHit> _parseSearch((String, int) input) =>
    parseBingResults(input.$1, input.$2);

WebPageContent _parsePage((String, String, String) input) =>
    parseWebPage(input.$1, input.$2, input.$3);
