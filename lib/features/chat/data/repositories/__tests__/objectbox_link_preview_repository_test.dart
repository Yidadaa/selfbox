import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:selfbox/core/error/app_failure.dart';
import 'package:selfbox/core/testing/fake_web_research_repository.dart';
import 'package:selfbox/core/testing/temp_storage.dart';
import 'package:selfbox/features/chat/data/datasources/link_preview_entity.dart';
import 'package:selfbox/features/chat/data/repositories/objectbox_link_preview_repository.dart';
import 'package:selfbox/features/chat/domain/repositories/web_research_repository.dart';

void main() {
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
  test('failed attempts survive reopening and do not fetch again', () async {
    final paths = createTempAppPaths();
    final store = await openTempStore(paths);
    final web = FakeWebResearchRepository()
      ..failure = const AppFailure.network(message: 'timeout');
    final repository = ObjectBoxLinkPreviewRepository(store, web);
    expect(
      (await repository.read('https://example.com').run()).isLeft(),
      isTrue,
    );
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
    expect(results.every((result) => result.isLeft()), isTrue);
    expect(web.urls, hasLength(2));
  });
  test(
    'clear drains in-flight writes before deleting persisted metadata',
    () async {
      final store = await openTempStore();
      final web = _DelayedWeb();
      final repository = ObjectBoxLinkPreviewRepository(store, web);
      final reading = repository.read('https://example.com').run();
      await web.started.future;
      expect(store.box<LinkPreviewEntity>().getAll(), hasLength(1));
      final concurrent = repository.read('https://example.com').run();
      expect(
        (await ObjectBoxLinkPreviewRepository(
          store,
          FakeWebResearchRepository(),
        ).read('https://example.com').run()).isLeft(),
        isTrue,
      );
      final clearing = repository.clearAll().run();
      expect(
        (await repository.read('https://dart.dev').run()).isLeft(),
        isTrue,
      );
      web.pending.complete(Right(web.page));
      await reading;
      expect((await concurrent).isRight(), isTrue);
      expect((await clearing).isRight(), isTrue);
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
