import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/error/app_failure.dart';
import '../../../../core/network/dio_factory.dart';
import '../../domain/models/ai_settings.dart';
import '../../domain/repositories/ai_settings_repository.dart';
import '../datasources/models_api.dart';

class HttpModelCatalog implements ModelCatalog {
  const HttpModelCatalog(this._dio);

  final DioFactory _dio;

  /// Anthropic pages at 20 by default; ask for everything in one call.
  static const _pageLimit = 1000;
  static const anthropicVersion = '2023-06-01';

  static Map<String, String> authHeaders(ApiFormat format, String apiKey) =>
      switch (format) {
        ApiFormat.chatCompletions ||
        ApiFormat.responses => {'Authorization': 'Bearer $apiKey'},
        ApiFormat.messages => {
          'x-api-key': apiKey,
          'anthropic-version': anthropicVersion,
        },
      };

  @override
  TaskEither<AppFailure, List<String>> fetch(
    ProviderConfig provider,
    String apiKey,
  ) => TaskEither.tryCatch(() async {
    final api = ModelsApi(
      _dio(
        baseUrl: provider.baseUrl,
        headers: authHeaders(provider.format, apiKey),
      ),
    );
    final list = await api.list(
      limit: provider.format == ApiFormat.messages ? _pageLimit : null,
    );
    return [for (final model in list.data) model.id];
  }, _toFailure);

  static AppFailure _toFailure(Object error, StackTrace stack) =>
      switch (error) {
        DioException(:final response?) => AppFailure.network(
          message: response.statusMessage ?? 'HTTP ${response.statusCode}',
          statusCode: response.statusCode,
        ),
        DioException(:final message) => AppFailure.network(
          message: message ?? 'connection failed',
        ),
        _ => AppFailure.unexpected(error: error, stackTrace: stack),
      };
}
