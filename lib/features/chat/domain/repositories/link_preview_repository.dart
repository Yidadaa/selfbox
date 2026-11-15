import 'package:fpdart/fpdart.dart';

import '../../../../core/error/app_failure.dart';
import 'web_research_repository.dart';

abstract interface class LinkPreviewRepository {
  TaskEither<AppFailure, WebPageContent> read(String url);
  TaskEither<AppFailure, Unit> clearAll();
}
