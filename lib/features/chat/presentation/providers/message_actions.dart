import 'package:fpdart/fpdart.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/chat_data_providers.dart';
import '../../domain/models/message.dart';

part '../../../../gen/features/chat/presentation/providers/message_actions.g.dart';

@riverpod
class MessageActions extends _$MessageActions {
  @override
  void build() {}

  /// Removes the message and the images only it referenced.
  Future<void> delete(Message message) async {
    final media = ref.read(mediaStoreProvider);
    await ref
        .read(messageRepositoryProvider)
        .delete(message.id)
        .flatMap(
          (_) => TaskEither.sequenceList(
            message.images.map(media.delete).toList(),
          ),
        )
        .run();
  }
}
