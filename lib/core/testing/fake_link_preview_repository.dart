import 'package:fpdart/fpdart.dart';

import '../../features/chat/domain/repositories/link_preview_repository.dart';
import '../../features/chat/domain/repositories/web_research_repository.dart';
import '../error/app_failure.dart';
import 'fake_web_research_repository.dart';

class FakeLinkPreviewRepository implements LinkPreviewRepository {
  FakeLinkPreviewRepository([FakeWebResearchRepository? web])
    : web = web ?? FakeWebResearchRepository();
  final FakeWebResearchRepository web;
  int clears = 0;
  @override
  TaskEither<AppFailure, WebPageContent> read(String url) => web.read(url);
  @override
  TaskEither<AppFailure, Unit> clearAll() => TaskEither(() async {
    clears++;
    return const Right(unit);
  });
}
