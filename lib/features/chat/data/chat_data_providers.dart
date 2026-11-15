import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/database/app_store.dart';
import '../../../core/logger/talker_provider.dart';
import '../../../core/network/dio_factory.dart';
import '../../../core/storage/app_paths.dart';
import '../domain/repositories/language_model_factory.dart';
import '../domain/repositories/link_preview_repository.dart';
import '../domain/repositories/message_repository.dart';
import '../domain/repositories/web_research_repository.dart';
import 'datasources/media_store.dart';
import 'datasources/public_web_http.dart';
import 'repositories/bing_web_research_repository.dart';
import 'repositories/objectbox_link_preview_repository.dart';
import 'repositories/objectbox_message_repository.dart';
import 'repositories/sdk_language_model_factory.dart';

part '../../../gen/features/chat/data/chat_data_providers.g.dart';

@Riverpod(keepAlive: true)
LinkPreviewRepository linkPreviewRepository(Ref ref) =>
    ObjectBoxLinkPreviewRepository(
      ref.watch(appStoreProvider),
      ref.watch(webResearchRepositoryProvider),
    );

@Riverpod(keepAlive: true)
MessageRepository messageRepository(Ref ref) =>
    ObjectBoxMessageRepository(ref.watch(appStoreProvider));

@Riverpod(keepAlive: true)
MediaStore mediaStore(Ref ref) => MediaStore(ref.watch(appPathsProvider));

@Riverpod(keepAlive: true)
LanguageModelFactory languageModelFactory(Ref ref) =>
    SdkLanguageModelFactory(ref.watch(dioFactoryProvider));

@Riverpod(keepAlive: true)
WebResearchRepository webResearchRepository(Ref ref) {
  final dio = createPublicWebDio();
  ref.onDispose(() => dio.close(force: true));
  final talker = ref.watch(talkerProvider);
  return BingWebResearchRepository(
    dio,
    onFailure: (error, _) =>
        talker.warning('Web request failed (${error.runtimeType})'),
  );
}
