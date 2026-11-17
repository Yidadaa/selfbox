import 'package:fpdart/fpdart.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/error/app_failure.dart';
import '../../data/chat_data_providers.dart';
import '../../domain/models/message.dart';
import 'message_lookup.dart';

part '../../../../gen/features/chat/presentation/providers/message_actions.g.dart';

@riverpod
class MessageActions extends _$MessageActions {
  @override
  void build() {}

  Future<Either<AppFailure, Unit>> pin(int id, {required bool pinned}) =>
      ref.read(messageRepositoryProvider).setPinned(id, pinned: pinned).run();

  Future<Either<AppFailure, Unit>> clearPins() =>
      ref.read(messageRepositoryProvider).clearPins().run();

  /// Removes the message and the images only it referenced.
  Future<void> delete(Message message) async {
    final media = ref.read(mediaStoreProvider);
    final lease = ref.keepAlive();
    await ref
        .read(messageRepositoryProvider)
        .delete(message.id)
        .flatMap(
          (_) => TaskEither.sequenceList(
            message.images.map(media.delete).toList(),
          ),
        )
        .run()
        .whenComplete(lease.close);
    if (ref.mounted) {
      ref.invalidate(messageByIdProvider(message.id));
    }
  }
}
