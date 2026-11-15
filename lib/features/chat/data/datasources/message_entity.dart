import 'package:objectbox/objectbox.dart';

import '../../domain/models/message.dart';

/// Mutable ObjectBox row; mapped to the immutable [Message] at the boundary.
@Entity()
class MessageEntity {
  MessageEntity({
    required this.createdAt,
    required this.author,
    required this.text,
    required this.images,
    required this.askedAi,
    this.quotedMessageIds = '',
    this.id = 0,
  });

  @Id()
  int id;

  @Index()
  @Property(type: PropertyType.date)
  DateTime createdAt;

  /// [MessageAuthor.index]; stored as an int so renaming enum values is safe
  /// as long as the order is kept.
  int author;

  String text;

  List<String> images;

  bool askedAi;

  String quotedMessageIds;
}

extension MessageEntityMapper on MessageEntity {
  Message toDomain() => Message(
    id: id,
    createdAt: createdAt,
    author: MessageAuthor.values[author],
    text: text,
    images: List.unmodifiable(images),
    askedAi: askedAi,
    quotedMessageIds: _decodeQuotedIds(quotedMessageIds),
  );
}

extension MessageDraftMapper on MessageDraft {
  MessageEntity toEntity(DateTime createdAt) => MessageEntity(
    createdAt: createdAt,
    author: author.index,
    text: text.trim(),
    images: List.of(images),
    askedAi: askedAi,
    quotedMessageIds: quotedMessageIds.join(','),
  );
}

List<int> _decodeQuotedIds(String value) => [
  for (final part in value.split(',')) ?int.tryParse(part),
];
