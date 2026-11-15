import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:selfbox/core/error/app_failure.dart';
import 'package:selfbox/features/chat/data/datasources/link_preview_entity.dart';
import 'package:selfbox/features/chat/data/repositories/objectbox_link_preview_repository.dart';
import 'package:selfbox/features/chat/domain/repositories/web_research_repository.dart';

import '../../../../support/fake_web_research_repository.dart';
import '../../../../support/temp_storage.dart';

void main() {
  for (final stillFails in [true, false]) {
    test(
      'version 1 failures retry after reopening, failure=$stillFails',
      () async {
        final paths = createTempAppPaths();
        final store = await openTempStore(paths);
        final row = LinkPreviewEntity(
          sourceUrl: 'https://example.com',
          url: 'https://example.com',
          title: '',
          description: '',
          iconUrl: '',
          unavailable: true,
          fetchVersion: 1,
        );
        await store.box<LinkPreviewEntity>().putAsync(row);
        final web = FakeWebResearchRepository();
        if (stillFails) {
          web.failure = const AppFailure.network(message: 'offline');
        }
        final repository = ObjectBoxLinkPreviewRepository(store, web);
        expect(
          (await repository.read(row.sourceUrl).run()).isLeft(),
          stillFails,
        );
        store.close();
        final reopened = ObjectBoxLinkPreviewRepository(
          await openTempStore(paths),
          web,
        );
        expect((await reopened.read(row.sourceUrl).run()).isLeft(), stillFails);
        expect(web.urls, hasLength(stillFails ? 2 : 1));
      },
    );
  }
  test('successful migration updates the existing row to version 2', () async {
    final store = await openTempStore();
    final box = store.box<LinkPreviewEntity>();
    final id = await box.putAsync(
      LinkPreviewEntity(
        sourceUrl: 'https://example.com',
        url: 'https://example.com',
        title: '',
        description: '',
        iconUrl: '',
        unavailable: true,
        fetchVersion: 1,
      ),
    );
    final repository = ObjectBoxLinkPreviewRepository(
      store,
      FakeWebResearchRepository(),
    );
    expect(
      (await repository.read('https://example.com').run()).isRight(),
      isTrue,
    );
    final row = box.getAll().single;
    expect(row.id, id);
    expect(row.fetchVersion, 2);
    expect(row.unavailable, isFalse);
  });

  test('metadata survives repository recreation and offline reads', () async {
    final paths = createTempAppPaths();
    final store = await openTempStore(paths);
    final web = FakeWebResearchRepository()
      ..page = const WebPageContent(
        title: 'Saved title',
        url: 'https://example.com/final',
        text: 'Full body',
        description: 'Saved summary',
        iconUrl: 'https://example.com/icon.png',
      );
    final repository = ObjectBoxLinkPreviewRepository(store, web);
    final first = await repository.read('https://example.com').run();
    expect(first.toNullable()?.text, isEmpty);
    web.failure = const AppFailure.network(message: 'offline');
    store.close();
    final reopened = ObjectBoxLinkPreviewRepository(
      await openTempStore(paths),
      web,
    );
    expect(await reopened.read('https://example.com').run(), first);
    expect(web.urls, hasLength(1));
    await reopened.clearAll().run();
    expect((await reopened.read('https://example.com').run()).isLeft(), isTrue);
  });
  test('failed attempts can recover after reopening and deduplicate', () async {
    final paths = createTempAppPaths();
    final store = await openTempStore(paths);
    final web = FakeWebResearchRepository()
      ..failure = const AppFailure.network(message: 'timeout');
    final repository = ObjectBoxLinkPreviewRepository(store, web);
    expect(
      (await repository.read('https://example.com').run()).isLeft(),
      isTrue,
    );
    expect(store.box<LinkPreviewEntity>().getAll(), isEmpty);
    web.failure = null;
    expect(
      (await repository.read('https://example.com/second').run()).isRight(),
      isTrue,
    );
    expect(web.urls, ['https://example.com', 'https://example.com/second']);
    store.close();
    final reopened = ObjectBoxLinkPreviewRepository(
      await openTempStore(paths),
      web,
    );
    final results = await Future.wait(
      List.generate(4, (_) => reopened.read('https://example.com').run()),
    );
    expect(results.every((result) => result.isRight()), isTrue);
    expect(web.urls, hasLength(3));
    expect(await reopened.read('https://example.com').run(), results.first);
    expect(web.urls, hasLength(3));
  });
  test(
    'clear drains in-flight writes before deleting persisted metadata',
    () async {
      final store = await openTempStore();
      final web = _DelayedWeb();
      final repository = ObjectBoxLinkPreviewRepository(store, web);
      final reading = repository.read('https://example.com').run();
      await web.started.future;
      expect(store.box<LinkPreviewEntity>().getAll(), isEmpty);
      final concurrent = repository.read('https://example.com').run();
      final clearing = repository.clearAll().run();
      expect(
        (await repository.read('https://dart.dev').run()).isLeft(),
        isTrue,
      );
      web.pending.complete(Right(web.page));
      await reading;
      expect((await concurrent).isRight(), isTrue);
      expect((await clearing).isRight(), isTrue);
      expect(store.box<LinkPreviewEntity>().getAll(), isEmpty);
      final offline = FakeWebResearchRepository()
        ..failure = const AppFailure.network(message: 'offline');
      expect(
        (await ObjectBoxLinkPreviewRepository(
          store,
          offline,
        ).read('https://example.com').run()).isLeft(),
        isTrue,
      );
    },
  );
}

class _DelayedWeb extends FakeWebResearchRepository {
  final started = Completer<void>();
  final pending = Completer<Either<AppFailure, WebPageContent>>();
  @override
  TaskEither<AppFailure, WebPageContent> read(String url) => TaskEither(() {
    started.complete();
    return pending.future;
  });
}
