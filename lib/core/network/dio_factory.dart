import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:talker_dio_logger/talker_dio_logger.dart';

import '../logger/talker_provider.dart';

part '../../gen/core/network/dio_factory.g.dart';

typedef DioFactory = Dio Function({
  required String baseUrl,
  Map<String, String> headers,
});

/// Builds Dio clients with shared timeouts and Talker logging. Headers and
/// bodies are not logged: requests carry API keys and personal notes.
@Riverpod(keepAlive: true)
DioFactory dioFactory(Ref ref) {
  final talker = ref.watch(talkerProvider);
  return ({required baseUrl, headers = const {}}) =>
      Dio(
          BaseOptions(
            baseUrl: baseUrl.endsWith('/') ? baseUrl : '$baseUrl/',
            headers: headers,
            connectTimeout: const Duration(seconds: 15),
            receiveTimeout: const Duration(seconds: 60),
          ),
        )
        ..interceptors.add(
          TalkerDioLogger(
            talker: talker,
            settings: const TalkerDioLoggerSettings(printRequestData: false),
          ),
        );
}
