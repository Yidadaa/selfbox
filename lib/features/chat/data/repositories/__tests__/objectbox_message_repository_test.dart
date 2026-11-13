import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:selfbox/core/error/app_failure.dart';
import 'package:selfbox/core/testing/temp_storage.dart';
import 'package:selfbox/features/chat/data/repositories/objectbox_message_repository.dart';
import 'package:selfbox/features/chat/domain/models/message.dart';

final _t0 = DateTime(2026, 11, 10, 9);

Future<ObjectBoxMessageRepository> _repo() async => ObjectBoxMessageRepository(
  await openTempStore(),
  clock: steppingClock(_t0, step: const Duration(hours: 6)),
);

Future<Message> _add(
  ObjectBoxMessageRepository repo,
  String text, {
  MessageAuthor author = MessageAuthor.me,
  List<String> images = const [],
}) async =>
    (await repo
            .add(MessageDraft(author: author, text: text, images: images))
            .run())
        .getOrElse((f) => fail('$f'));

List<String> _texts(Either<AppFailure, List<Message>> result) =>
    result.getOrElse((f) => fail('$f')).map((m) => m.text).toList();

void main() {
  group('ObjectBoxMessageRepository', () {
    test('clear removes every row and the store remains writable', () async {
      final repo = await _repo();
      await _add(repo, 'first');
      await _add(repo, 'second');
      expect((await repo.clearAll().run()).isRight(), true);
      expect(_texts(await repo.latest(20).run()), isEmpty);
      await _add(repo, 'new');
      expect(_texts(await repo.latest(20).run()), ['new']);
    });
    test('add assigns an id and the clock time', () async {
      final repo = await _repo();
      final message = await _add(repo, 'first');

      expect(message.id, greaterThan(0));
      expect(message.createdAt, _t0);
      expect(message.author, MessageAuthor.me);
    });

    test('add rejects an empty draft with a validation failure', () async {
      final repo = await _repo();
      final result = await repo
          .add(const MessageDraft(author: MessageAuthor.me, text: '  '))
          .run();
      expect(result.getLeft().toNullable(), isA<ValidationFailure>());
    });

    test('image-only messages keep their relative paths', () async {
      final repo = await _repo();
      final message = await _add(repo, '', images: ['media/a.jpg']);
      final loaded = (await repo.byId(message.id).run()).getOrElse(
        (f) => fail('$f'),
      );
      expect(loaded.toNullable()?.images, ['media/a.jpg']);
    });

    test('allImagePaths returns unique paths in chronological order', () async {
      final repo = await _repo();
      await _add(repo, 'first', images: ['media/a.jpg', 'media/b.jpg']);
      await _add(repo, 'second', images: ['media/c.jpg', 'media/a.jpg']);
      await _add(repo, 'without image');

      final result = await repo.allImagePaths().run();
      expect(result.getOrElse((failure) => fail('$failure')), [
        'media/a.jpg',
        'media/b.jpg',
        'media/c.jpg',
      ]);
    });

    test('byId returns none for unknown ids', () async {
      final repo = await _repo();
      final result = await repo.byId(999).run();
      expect(result.getOrElse((f) => fail('$f')), isA<None>());
    });

    test('latest is newest-first and honours the limit', () async {
      final repo = await _repo();
      for (final text in ['a', 'b', 'c']) {
        await _add(repo, text);
      }
      expect(_texts(await repo.latest(2).run()), ['c', 'b']);
    });

    test(
      'latest pages by offset, including messages sharing a timestamp',
      () async {
        final repo = ObjectBoxMessageRepository(
          await openTempStore(),
          clock: () => _t0,
        );
        for (final text in ['a', 'b', 'c', 'd', 'e']) {
          await _add(repo, text);
        }
        expect(_texts(await repo.latest(2).run()), ['e', 'd']);
        expect(_texts(await repo.latest(2, offset: 2).run()), ['c', 'b']);
        expect(_texts(await repo.latest(2, offset: 4).run()), ['a']);
        expect(_texts(await repo.latest(2, offset: 5).run()), isEmpty);
      },
    );

    test('watchLatest emits immediately and again after writes', () async {
      final repo = await _repo();
      await _add(repo, 'a');

      final emissions = <List<String>>[];
      final sub = repo
          .watchLatest(2)
          .listen((list) => emissions.add(list.map((m) => m.text).toList()));
      addTearDown(sub.cancel);

      await pumpEventQueueUntil(() => emissions.isNotEmpty);
      await _add(repo, 'b');
      await _add(repo, 'c');
      await pumpEventQueueUntil(() => emissions.last.first == 'c');

      expect(emissions.first, ['a']);
      expect(emissions.last, ['c', 'b']);
    });

    test('find matches every keyword, case-insensitively', () async {
      final repo = await _repo();
      await _add(repo, 'Weekly report due Friday');
      await _add(repo, 'weekly groceries');
      await _add(repo, 'report the bug');

      final result = await repo
          .find(const MessageQuery(keywords: 'REPORT weekly'))
          .run();
      expect(_texts(result), ['Weekly report due Friday']);
    });

    test('find matches CJK substrings', () async {
      final repo = await _repo();
      await _add(repo, '明天要提交周报');
      await _add(repo, '周末想去爬山');

      final result = await repo.find(const MessageQuery(keywords: '周报')).run();
      expect(_texts(result), ['明天要提交周报']);
    });

    test('find filters by author and inclusive time range', () async {
      final repo = await _repo();
      await _add(repo, 'm0'); // t0
      await _add(repo, 'a1', author: MessageAuthor.ai); // t0 + 6h
      await _add(repo, 'm2'); // t0 + 12h
      await _add(repo, 'm3'); // t0 + 18h

      final mine = await repo
          .find(const MessageQuery(author: MessageAuthor.me))
          .run();
      expect(_texts(mine), ['m3', 'm2', 'm0']);

      final window = await repo
          .find(
            MessageQuery(
              from: _t0.add(const Duration(hours: 6)),
              to: _t0.add(const Duration(hours: 12)),
            ),
          )
          .run();
      expect(_texts(window), ['m2', 'a1']);
    });

    test('find with no criteria returns the newest up to the limit', () async {
      final repo = await _repo();
      for (var i = 0; i < 5; i++) {
        await _add(repo, 'n$i');
      }
      final result = await repo.find(const MessageQuery(limit: 3)).run();
      expect(_texts(result), ['n4', 'n3', 'n2']);
    });

    test(
      'around returns an oldest-first window centred on the anchor',
      () async {
        final repo = await _repo();
        final ids = <int>[];
        for (var i = 0; i < 7; i++) {
          ids.add((await _add(repo, 'w$i')).id);
        }

        final result = await repo.around(ids[3], before: 2, after: 1).run();
        expect(_texts(result), ['w1', 'w2', 'w3', 'w4']);
      },
    );

    test('around clips at the ends of the timeline', () async {
      final repo = await _repo();
      final first = await _add(repo, 'only');
      final result = await repo.around(first.id, before: 3, after: 3).run();
      expect(_texts(result), ['only']);
    });

    test('around an unknown id is empty', () async {
      final repo = await _repo();
      expect(_texts(await repo.around(42).run()), isEmpty);
    });

    test('delete removes the message', () async {
      final repo = await _repo();
      final message = await _add(repo, 'gone');
      await repo.delete(message.id).run();

      expect(_texts(await repo.latest(10).run()), isEmpty);
    });
  });
}

Future<void> pumpEventQueueUntil(bool Function() condition) async {
  for (var i = 0; i < 200 && !condition(); i++) {
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
  expect(condition(), isTrue, reason: 'condition not met in time');
}
