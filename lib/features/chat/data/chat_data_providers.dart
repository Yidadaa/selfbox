import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/database/app_store.dart';
import '../../../core/storage/app_paths.dart';
import '../domain/repositories/message_repository.dart';
import 'datasources/media_store.dart';
import 'repositories/objectbox_message_repository.dart';

part '../../../gen/features/chat/data/chat_data_providers.g.dart';

@Riverpod(keepAlive: true)
MessageRepository messageRepository(Ref ref) =>
    ObjectBoxMessageRepository(ref.watch(appStoreProvider));

@Riverpod(keepAlive: true)
MediaStore mediaStore(Ref ref) => MediaStore(ref.watch(appPathsProvider));
