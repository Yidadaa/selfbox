import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:selfbox/core/network/dio_factory.dart';
import 'package:selfbox/features/chat/data/repositories/sdk_language_model_factory.dart';
import 'package:selfbox/features/settings/domain/models/ai_settings.dart';

void main() {
  for (final format in ApiFormat.values) {
    test('passes safe custom headers to the ${format.name} SDK client', () {
      final client = Dio();
      Map<String, String>? receivedHeaders;
      String? receivedBaseUrl;
      Dio createClient({
        required String baseUrl,
        Map<String, String> headers = const {},
      }) {
        receivedBaseUrl = baseUrl;
        receivedHeaders = headers;
        return client;
      }

      final DioFactory dioFactory = createClient;
      final provider = ProviderConfig(
        id: 'p1',
        name: 'Gateway',
        format: format,
        baseUrl: 'https://gw.example.com/v1',
        headers: switch (format) {
          ApiFormat.chatCompletions || ApiFormat.responses => const {
            'X-Trace': 'trace-1',
            'authorization': 'custom-auth',
          },
          ApiFormat.messages => const {
            'X-Trace': 'trace-1',
            'X-API-KEY': 'custom-key',
            'Anthropic-Version': 'custom-version',
          },
        },
      );

      final handle = SdkLanguageModelFactory(dioFactory)
          .create(provider, 'secret', 'model-x');

      expect(receivedHeaders, {'X-Trace': 'trace-1'});
      expect(receivedBaseUrl, 'https://gw.example.com/v1');
      handle.dispose();
    });
  }
}
