import 'package:fpdart/fpdart.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/error/app_failure.dart';
import '../../data/chat_data_providers.dart';
import '../../domain/models/message.dart';

part '../../../../gen/features/chat/presentation/providers/message_search.g.dart';

@riverpod
Future<Either<AppFailure, List<Message>>> messageSearch(
  Ref ref,
  String keywords,
) async {
  if (keywords.trim().isEmpty) return const Right([]);
  return ref
      .watch(messageRepositoryProvider)
      .find(MessageQuery(keywords: keywords, limit: 100))
      .run();
}
