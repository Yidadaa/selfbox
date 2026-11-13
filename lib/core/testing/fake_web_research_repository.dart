import 'package:fpdart/fpdart.dart';

import '../../features/chat/domain/repositories/web_research_repository.dart';
import '../error/app_failure.dart';

class FakeWebResearchRepository implements WebResearchRepository {
  List<WebSearchHit> hits = const [];
  WebPageContent page = const WebPageContent(
    title: 'Example',
    url: 'https://example.com',
    text: 'Example page',
  );
  AppFailure? failure;
  final queries = <String>[];
  final urls = <String>[];
  @override
  TaskEither<AppFailure, List<WebSearchHit>> search(
    String query, {
    required int limit,
  }) {
    queries.add(query);
    return failure == null
        ? TaskEither.right(hits.take(limit).toList())
        : TaskEither.left(failure!);
  }

  @override
  TaskEither<AppFailure, WebPageContent> read(String url) {
    urls.add(url);
    return failure == null ? TaskEither.right(page) : TaskEither.left(failure!);
  }
}
