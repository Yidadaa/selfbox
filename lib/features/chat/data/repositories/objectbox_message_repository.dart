import 'package:fpdart/fpdart.dart' hide Order;

import '../../../../core/error/app_failure.dart';
import '../../../../gen/database/objectbox.g.dart';
import '../../domain/models/message.dart';
import '../../domain/repositories/message_repository.dart';
import '../datasources/message_entity.dart';

class ObjectBoxMessageRepository implements MessageRepository {
  ObjectBoxMessageRepository(Store store, {DateTime Function()? clock})
    : _box = store.box<MessageEntity>(),
      _clock = clock ?? DateTime.now;

  final Box<MessageEntity> _box;
  final DateTime Function() _clock;

  @override
  TaskEither<AppFailure, Unit> clearAll() => _run(() async {
    await _box.removeAllAsync();
    return unit;
  });

  static AppFailure _dbFailure(Object error, StackTrace _) => switch (error) {
    final AppFailure failure => failure,
    _ => AppFailure.database(message: error.toString()),
  };

  TaskEither<AppFailure, T> _run<T>(Future<T> Function() body) =>
      TaskEither.tryCatch(body, _dbFailure);

  QueryBuilder<MessageEntity> _newestFirst([Condition<MessageEntity>? where]) =>
      _box.query(where)
        ..order(MessageEntity_.createdAt, flags: Order.descending);

  @override
  Stream<List<Message>> watchLatest(int limit) =>
      _newestFirst().watch(triggerImmediately: true).asyncMap((query) async {
        query.limit = limit;
        final rows = await query.findAsync();
        return List<Message>.unmodifiable(rows.map((e) => e.toDomain()));
      });

  @override
  TaskEither<AppFailure, Message> add(MessageDraft draft) => _run(() async {
    if (draft.isEmpty) {
      throw const AppFailure.validation(message: 'empty message');
    }
    final entity = await _box.putAndGetAsync(draft.toEntity(_clock()));
    return entity.toDomain();
  });

  @override
  TaskEither<AppFailure, Unit> delete(int id) => _run(() async {
    await _box.removeAsync(id);
    return unit;
  });

  @override
  TaskEither<AppFailure, Option<Message>> byId(int id) => _run(
    () async =>
        Option.fromNullable(await _box.getAsync(id)).map((e) => e.toDomain()),
  );

  @override
  TaskEither<AppFailure, List<Message>> latest(int limit) =>
      find(MessageQuery(limit: limit));

  @override
  TaskEither<AppFailure, List<String>> allImagePaths() => _run(() async {
    final query = (_box.query()..order(MessageEntity_.createdAt)).build();
    try {
      final paths = <String>{};
      for (final message in await query.findAsync()) {
        paths.addAll(message.images);
      }
      return List.unmodifiable(paths);
    } finally {
      query.close();
    }
  });

  @override
  TaskEither<AppFailure, List<Message>> find(MessageQuery query) =>
      _run(() async {
        final conditions = <Condition<MessageEntity>>[
          for (final term in query.terms)
            MessageEntity_.text.contains(term, caseSensitive: false),
          if (query.from case final from?)
            MessageEntity_.createdAt.greaterOrEqualDate(from),
          if (query.to case final to?)
            MessageEntity_.createdAt.lessOrEqualDate(to),
          if (query.author case final author?)
            MessageEntity_.author.equals(author.index),
        ];
        final where = conditions.isEmpty
            ? null
            : conditions.reduce((a, b) => a.and(b));
        final built = _newestFirst(where).build()..limit = query.limit;
        try {
          return _toDomain(await built.findAsync());
        } finally {
          built.close();
        }
      });

  @override
  TaskEither<AppFailure, List<Message>> around(
    int id, {
    int before = 5,
    int after = 5,
  }) => _run(() async {
    final anchor = await _box.getAsync(id);
    if (anchor == null) return const <Message>[];

    final earlierQuery = _newestFirst(
      MessageEntity_.createdAt.lessThanDate(anchor.createdAt),
    ).build()..limit = before;
    final laterQuery = (_box.query(
      MessageEntity_.createdAt.greaterThanDate(anchor.createdAt),
    )..order(MessageEntity_.createdAt)).build()..limit = after;
    try {
      final earlier = await earlierQuery.findAsync();
      final later = await laterQuery.findAsync();
      return _toDomain([...earlier.reversed, anchor, ...later]);
    } finally {
      earlierQuery.close();
      laterQuery.close();
    }
  });

  List<Message> _toDomain(List<MessageEntity> rows) =>
      List.unmodifiable(rows.map((e) => e.toDomain()));
}
