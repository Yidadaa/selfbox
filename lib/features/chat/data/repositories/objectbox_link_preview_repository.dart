import 'package:fpdart/fpdart.dart';

import '../../../../core/error/app_failure.dart';
import '../../../../gen/database/objectbox.g.dart';
import '../../domain/repositories/link_preview_repository.dart';
import '../../domain/repositories/web_research_repository.dart';
import '../datasources/link_preview_entity.dart';

class ObjectBoxLinkPreviewRepository implements LinkPreviewRepository {
  ObjectBoxLinkPreviewRepository(Store store, this.web)
    : _box = store.box<LinkPreviewEntity>();
  final Box<LinkPreviewEntity> _box;
  final WebResearchRepository web;
  final _pending = <String, Future<Either<AppFailure, WebPageContent>>>{};
  Future<Either<AppFailure, Unit>>? _clearing;

  @override
  TaskEither<AppFailure, WebPageContent> read(String url) => TaskEither(() {
    if (_clearing != null) {
      return Future.value(
        const Left(AppFailure.database(message: 'Data reset in progress')),
      );
    }
    return _pending.putIfAbsent(
      url,
      () => _load(url).run().whenComplete(() {
        _pending.remove(url);
      }),
    );
  });

  TaskEither<AppFailure, WebPageContent> _load(String url) =>
      TaskEither.tryCatch(() async {
        final query = _box
            .query(LinkPreviewEntity_.sourceUrl.equals(url))
            .build();
        try {
          return await query.findFirstAsync();
        } finally {
          query.close();
        }
      }, _failure).flatMap(
        (cached) => cached != null
            ? cached.unavailable
                  ? TaskEither.left(
                      const AppFailure.network(
                        message: 'Link preview unavailable',
                      ),
                    )
                  : TaskEither.right(cached.toDomain())
            : _fetchOnce(url),
      );

  TaskEither<AppFailure, WebPageContent> _fetchOnce(String url) =>
      TaskEither.tryCatch(
        () => _box.putAsync(
          LinkPreviewEntity(
            sourceUrl: url,
            url: url,
            title: '',
            description: '',
            iconUrl: '',
            unavailable: true,
          ),
        ),
        _failure,
      ).flatMap(
        (id) => web
            .read(url)
            .flatMap(
              (page) => TaskEither.tryCatch(() async {
                final row = LinkPreviewEntity(
                  id: id,
                  sourceUrl: url,
                  url: page.url,
                  title: page.title,
                  description: page.description,
                  iconUrl: page.iconUrl,
                );
                await _box.putAsync(row);
                return row.toDomain();
              }, _failure),
            ),
      );

  @override
  TaskEither<AppFailure, Unit> clearAll() => TaskEither(
    () => _clearing ??= TaskEither.tryCatch(() async {
      // A completed reset must not be repopulated by an earlier HTTP response.
      await Future.wait(_pending.values.toList());
      await _box.removeAllAsync();
      return unit;
    }, _failure).run().whenComplete(() => _clearing = null),
  );
}

AppFailure _failure(Object error, StackTrace _) =>
    AppFailure.database(message: error.toString());
