import 'dart:async';

import 'package:fpdart/fpdart.dart';

import '../../features/chat/domain/models/message.dart';
import '../../features/chat/domain/repositories/message_repository.dart';
import '../error/app_failure.dart';

/// In-memory [MessageRepository] for widget and provider tests, where
/// ObjectBox's native async queries cannot run inside fake async zones.
class FakeMessageRepository implements MessageRepository {
  FakeMessageRepository({
    List<Message> seed = const [],
    DateTime Function()? clock,
  }) : _clock = clock ?? (() => DateTime(2026, 11, 12, 9)) {
    _rows.addAll(seed);
    _nextId = seed.fold(0, (max, m) => m.id > max ? m.id : max) + 1;
  }

  final DateTime Function() _clock;
  final _rows = <Message>[];
  final _changes = StreamController<void>.broadcast();
  late int _nextId;

  /// Every draft passed to [add], in order.
  final added = <MessageDraft>[];

  @override
  TaskEither<AppFailure, Unit> clearAll() {
    _rows.clear();
    _changes.add(null);
    return TaskEither.right(unit);
  }

  Option<AppFailure> failNextAdd = const None();

  List<Message> get _newestFirst =>
      [..._rows]..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  @override
  Stream<List<Message>> watchLatest(int limit) async* {
    yield _newestFirst.take(limit).toList();
    await for (final _ in _changes.stream) {
      yield _newestFirst.take(limit).toList();
    }
  }

  @override
  TaskEither<AppFailure, Message> add(MessageDraft draft) {
    added.add(draft);
    final failure = failNextAdd;
    failNextAdd = const None();
    return failure.match(() {
      final message = Message(
        id: _nextId++,
        createdAt: _clock(),
        author: draft.author,
        text: draft.text.trim(),
        images: draft.images,
        askedAi: draft.askedAi,
      );
      _rows.add(message);
      _changes.add(null);
      return TaskEither.right(message);
    }, TaskEither.left);
  }

  @override
  TaskEither<AppFailure, Unit> delete(int id) {
    _rows.removeWhere((m) => m.id == id);
    _changes.add(null);
    return TaskEither.right(unit);
  }

  @override
  TaskEither<AppFailure, Option<Message>> byId(int id) => TaskEither.right(
    Option.fromNullable(_rows.where((m) => m.id == id).firstOrNull),
  );

  @override
  TaskEither<AppFailure, List<Message>> latest(int limit) =>
      TaskEither.right(_newestFirst.take(limit).toList());

  @override
  TaskEither<AppFailure, List<Message>> find(MessageQuery query) {
    bool matches(Message m) =>
        query.terms.every(
          (t) => m.text.toLowerCase().contains(t.toLowerCase()),
        ) &&
        (query.author == null || m.author == query.author) &&
        (query.from == null || !m.createdAt.isBefore(query.from!)) &&
        (query.to == null || !m.createdAt.isAfter(query.to!));
    return TaskEither.right(
      _newestFirst.where(matches).take(query.limit).toList(),
    );
  }

  @override
  TaskEither<AppFailure, List<Message>> around(
    int id, {
    int before = 5,
    int after = 5,
  }) {
    final ordered = _newestFirst.reversed.toList();
    final index = ordered.indexWhere((m) => m.id == id);
    if (index < 0) return TaskEither.right(const []);
    final start = (index - before).clamp(0, ordered.length);
    final end = (index + after + 1).clamp(0, ordered.length);
    return TaskEither.right(ordered.sublist(start, end));
  }
}
