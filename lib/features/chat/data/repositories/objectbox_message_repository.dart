import 'package:fpdart/fpdart.dart' hide Order;

import '../../../../core/error/app_failure.dart';
import '../../../../gen/database/objectbox.g.dart';
import '../../domain/models/message.dart';
import '../../domain/repositories/message_repository.dart';
import '../datasources/message_entity.dart';
import '../datasources/pinned_message_state_entity.dart';

class ObjectBoxMessageRepository implements MessageRepository {
  ObjectBoxMessageRepository(Store store, {DateTime Function()? clock})
    : _store = store,
      _box = store.box<MessageEntity>(),
      _clock = clock ?? DateTime.now;

  final Box<MessageEntity> _box;
  final Store _store;
  final DateTime Function() _clock;
  Map<int, Message> _liveMessages = {};

  @override
  Stream<List<Message>> watchPinned() => _store
      .box<PinnedMessageStateEntity>()
      .query()
      .watch(triggerImmediately: true)
      .asyncMap((query) async {
        final states = await query.findAsync();
        final ids = states.firstOrNull?.messageIds ?? const <int>[];
        final rows = await _box.getManyAsync(ids);
        final messages =
            rows
                .whereType<MessageEntity>()
                .map((row) => row.toDomain())
                .toList()
              ..sort((a, b) {
                final time = b.createdAt.compareTo(a.createdAt);
                return time == 0 ? b.id.compareTo(a.id) : time;
              });
        return List<Message>.unmodifiable(messages);
      });

  @override
  TaskEither<AppFailure, Unit> setPinned(int id, {required bool pinned}) =>
      _run(() async {
        await _store.runInTransactionAsync(TxMode.write, _setPinned, (
          id,
          pinned,
        ));
        return unit;
      });

  @override
  TaskEither<AppFailure, Unit> clearPins() => _run(() async {
    await _store.runInTransactionAsync(TxMode.write, _clearPins, 0);
    return unit;
  });

  @override
  TaskEither<AppFailure, Unit> clearAll() => _run(() async {
    await _store.runInTransactionAsync(TxMode.write, _deleteAll, 0);
    _liveMessages = {};
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
        ..order(MessageEntity_.createdAt, flags: Order.descending)
        ..order(MessageEntity_.id, flags: Order.descending);

  @override
  Stream<List<Message>> watchLatest(int limit) => _newestFirst()
      .watch(triggerImmediately: true)
      .asyncMap((query) async {
        query.limit = limit;
        final ids = await query.findIdsAsync();
        final retained = _liveMessages;
        final missing = ids.where((id) => !retained.containsKey(id)).toList();
        final loaded = missing.isEmpty
            ? const <MessageEntity?>[]
            : await _box.getManyAsync(missing);
        final available = {
          ...retained,
          for (final row in loaded)
            if (row != null) row.id: row.toDomain(),
        };
        final messages = List<Message>.unmodifiable([
          for (final id in ids) ?available[id],
        ]);
        _liveMessages = {for (final message in messages) message.id: message};
        return messages;
      })
      .distinct(
        (previous, next) =>
            previous.length == next.length &&
            previous.indexed.every(
              (entry) => identical(entry.$2, next[entry.$1]),
            ),
      );

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
    await _store.runInTransactionAsync(TxMode.write, _deleteMessage, id);
    return unit;
  });

  @override
  TaskEither<AppFailure, Option<Message>> byId(int id) => _run(
    () async =>
        Option.fromNullable(await _box.getAsync(id)).map((e) => e.toDomain()),
  );

  @override
  TaskEither<AppFailure, List<Message>> latest(int limit, {int offset = 0}) =>
      _run(() async {
        final query = _newestFirst().build()
          ..limit = limit
          ..offset = offset;
        try {
          return _toDomain(await query.findAsync());
        } finally {
          query.close();
        }
      });

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

void _setPinned(Store store, (int, bool) input) {
  if (input.$2 && !store.box<MessageEntity>().contains(input.$1)) return;
  final box = store.box<PinnedMessageStateEntity>();
  final state = box.get(1) ?? PinnedMessageStateEntity();
  final ids = state.messageIds.toSet();
  final changed = input.$2 ? ids.add(input.$1) : ids.remove(input.$1);
  if (!changed) return;
  state.messageIds = ids.toList();
  box.put(state);
}

void _clearPins(Store store, int _) {
  store.box<PinnedMessageStateEntity>().removeAll();
}

void _deleteMessage(Store store, int id) {
  store.box<MessageEntity>().remove(id);
  _setPinned(store, (id, false));
}

void _deleteAll(Store store, int _) {
  store.box<MessageEntity>().removeAll();
  _clearPins(store, 0);
}
