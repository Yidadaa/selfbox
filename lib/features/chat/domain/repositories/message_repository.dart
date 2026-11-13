import 'package:fpdart/fpdart.dart';

import '../../../../core/error/app_failure.dart';
import '../models/message.dart';

/// The chat timeline. Lists are newest-first unless stated otherwise.
abstract interface class MessageRepository {
  TaskEither<AppFailure, Unit> clearAll();

  /// The newest [limit] messages, re-emitted on every change.
  Stream<List<Message>> watchLatest(int limit);

  TaskEither<AppFailure, Message> add(MessageDraft draft);

  TaskEither<AppFailure, Unit> delete(int id);

  TaskEither<AppFailure, Option<Message>> byId(int id);

  /// The newest [limit] messages.
  TaskEither<AppFailure, List<Message>> latest(int limit);

  /// Every referenced image path, oldest message first, without duplicates.
  TaskEither<AppFailure, List<String>> allImagePaths();

  /// Newest-first matches for [query].
  TaskEither<AppFailure, List<Message>> find(MessageQuery query);

  /// Oldest-first window: up to [before] earlier messages, the anchor, and up
  /// to [after] later ones. Empty when [id] does not exist.
  TaskEither<AppFailure, List<Message>> around(
    int id, {
    int before = 5,
    int after = 5,
  });
}
