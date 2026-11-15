import 'dart:async';

import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/error/app_failure.dart';
import '../../domain/repositories/web_research_repository.dart';

Future<Either<AppFailure, WebPageContent>> raceWebReads(
  List<Dio> clients,
  Future<Either<AppFailure, WebPageContent>> Function(Dio, CancelToken) read,
) {
  final completion = Completer<Either<AppFailure, WebPageContent>>();
  final tokens = [for (final _ in clients) CancelToken()];
  var remaining = clients.length;
  for (var index = 0; index < clients.length; index++) {
    final token = tokens[index];
    unawaited(
      read(clients[index], token).then((result) {
        remaining--;
        if (completion.isCompleted) return;
        if (result.isRight() || remaining == 0) {
          completion.complete(result);
          for (final other in tokens) {
            if (other != token) other.cancel('Another route completed');
          }
        }
      }),
    );
  }
  return completion.future;
}
