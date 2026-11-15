import 'package:fpdart/fpdart.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/error/app_failure.dart';
import '../../data/chat_data_providers.dart';
import '../../domain/repositories/web_research_repository.dart';

part '../../../../gen/features/chat/presentation/providers/message_link_preview.g.dart';

@riverpod
Future<Either<AppFailure, WebPageContent>> messageLinkPreview(
  Ref ref,
  String url,
) async {
  return ref.watch(linkPreviewRepositoryProvider).read(url).run();
}
