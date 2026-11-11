import 'package:freezed_annotation/freezed_annotation.dart';

part '../../../../gen/features/chat/domain/models/message.freezed.dart';

enum MessageAuthor {
  /// The user writing to themself.
  me,

  /// The assistant replying in AI mode.
  ai,
}

@freezed
abstract class Message with _$Message {
  const factory Message({
    required int id,
    required DateTime createdAt,
    required MessageAuthor author,
    required String text,

    /// Paths relative to the app root, e.g. `media/<uuid>.jpg`.
    @Default(<String>[]) List<String> images,

    /// Whether this note was sent with AI mode on (a question to the agent).
    @Default(false) bool askedAi,
  }) = _Message;
}

@freezed
abstract class MessageDraft with _$MessageDraft {
  const factory MessageDraft({
    required MessageAuthor author,
    @Default('') String text,
    @Default(<String>[]) List<String> images,
    @Default(false) bool askedAi,
  }) = _MessageDraft;

  const MessageDraft._();

  bool get isEmpty => text.trim().isEmpty && images.isEmpty;
}

/// Filter for searching the timeline. All set fields must match.
@freezed
abstract class MessageQuery with _$MessageQuery {
  const factory MessageQuery({
    /// Whitespace-separated terms; every term must appear (case-insensitive).
    @Default('') String keywords,
    DateTime? from,
    DateTime? to,
    MessageAuthor? author,
    @Default(20) int limit,
  }) = _MessageQuery;

  const MessageQuery._();

  List<String> get terms => keywords
      .split(RegExp(r'\s+'))
      .where((term) => term.isNotEmpty)
      .toList(growable: false);
}
