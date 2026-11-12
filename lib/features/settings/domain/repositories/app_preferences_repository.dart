import 'package:fpdart/fpdart.dart';

import '../../../../core/error/app_failure.dart';
import '../models/app_preferences.dart';

abstract interface class AppPreferencesRepository {
  TaskEither<AppFailure, AppPreferences> load();

  TaskEither<AppFailure, Unit> save(AppPreferences preferences);

  TaskEither<AppFailure, Unit> clearAll();
}
