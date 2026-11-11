import 'package:flutter_test/flutter_test.dart';
import 'package:selfbox/core/error/app_failure.dart';
import 'package:selfbox/core/testing/fake_http_adapter.dart';
import 'package:selfbox/features/settings/data/repositories/http_model_catalog.dart';
import 'package:selfbox/features/settings/domain/models/ai_settings.dart';

const _gateway = ProviderConfig(
  id: 'p',
  name: 'Gateway',
  format: ApiFormat.chatCompletions,
  baseUrl: 'https://gateway.example.com/v1',
);

void main() {
  group('HttpModelCatalog', () {
    test('lists ids from GET {baseUrl}/models with a bearer token', () async {
      final adapter = FakeHttpAdapter(
        (_) => (
          status: 200,
          body: {
            'object': 'list',
            'data': [
              {'id': 'gpt-x', 'object': 'model'},
              {'id': 'gpt-y', 'object': 'model'},
            ],
          },
        ),
      );
      final catalog = HttpModelCatalog(fakeDioFactory(adapter));

      final ids = (await catalog.fetch(_gateway, 'sk-1').run()).getOrElse(
        (f) => fail('$f'),
      );

      expect(ids, ['gpt-x', 'gpt-y']);
      final request = adapter.requests.single;
      expect(request.uri.toString(), 'https://gateway.example.com/v1/models');
      expect(request.headers['Authorization'], 'Bearer sk-1');
    });

    test('uses Anthropic headers and asks for the full list', () async {
      final adapter = FakeHttpAdapter(
        (_) => (
          status: 200,
          body: {
            'data': [
              {'id': 'claude-x', 'display_name': 'Claude X'},
            ],
            'has_more': false,
          },
        ),
      );
      final catalog = HttpModelCatalog(fakeDioFactory(adapter));
      final anthropic = _gateway.copyWith(
        format: ApiFormat.messages,
        baseUrl: 'https://api.anthropic.com/v1/',
      );

      final ids = (await catalog.fetch(anthropic, 'ak').run()).getOrElse(
        (f) => fail('$f'),
      );

      expect(ids, ['claude-x']);
      final request = adapter.requests.single;
      expect(request.uri.path, '/v1/models');
      expect(request.uri.queryParameters['limit'], '1000');
      expect(request.headers['x-api-key'], 'ak');
      expect(
        request.headers['anthropic-version'],
        HttpModelCatalog.anthropicVersion,
      );
      expect(request.headers.containsKey('Authorization'), isFalse);
    });

    test('maps HTTP errors to a network failure with the status', () async {
      final adapter = FakeHttpAdapter(
        (_) => (status: 401, body: {'error': 'bad key'}),
      );
      final result = await HttpModelCatalog(fakeDioFactory(adapter))
          .fetch(_gateway, 'wrong')
          .run();

      final failure = result.getLeft().toNullable();
      expect(failure, isA<NetworkFailure>());
      expect((failure as NetworkFailure).statusCode, 401);
      expect(failure.isRetryable, isTrue);
    });

    test('an empty list is a valid answer', () async {
      final adapter = FakeHttpAdapter(
        (_) => (status: 200, body: {'data': <Object>[]}),
      );
      final result = await HttpModelCatalog(fakeDioFactory(adapter))
          .fetch(_gateway, 'k')
          .run();
      expect(result.getOrElse((f) => fail('$f')), isEmpty);
    });
  });
}
