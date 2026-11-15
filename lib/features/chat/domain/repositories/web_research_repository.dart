import 'package:fpdart/fpdart.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/error/app_failure.dart';

part '../../../../gen/features/chat/domain/repositories/web_research_repository.freezed.dart';

@freezed
abstract class WebSearchHit with _$WebSearchHit {
  const factory WebSearchHit({
    required String title,
    required String url,
    required String snippet,
  }) = _WebSearchHit;
}

@freezed
abstract class WebPageContent with _$WebPageContent {
  const factory WebPageContent({
    required String title,
    required String url,
    required String text,
    @Default('') String description,
    @Default('') String iconUrl,
    @Default(false) bool truncated,
  }) = _WebPageContent;
}

abstract interface class WebResearchRepository {
  TaskEither<AppFailure, List<WebSearchHit>> search(
    String query, {
    required int limit,
  });
  TaskEither<AppFailure, WebPageContent> read(String url);
}
