import 'package:fpdart/fpdart.dart';
import 'package:selfbox/core/error/app_failure.dart';
import 'package:selfbox/features/settings/domain/models/app_preferences.dart';
import 'package:selfbox/features/settings/domain/repositories/app_preferences_repository.dart';

class FakeAppPreferencesRepository implements AppPreferencesRepository {
  FakeAppPreferencesRepository({this.current = const AppPreferences()});

  AppPreferences current;
  AppFailure? failure;

  @override
  TaskEither<AppFailure, AppPreferences> load() => TaskEither.right(current);

  @override
  TaskEither<AppFailure, Unit> save(AppPreferences preferences) {
    final error = failure;
    if (error != null) return TaskEither.left(error);
    current = preferences;
    return TaskEither.right(unit);
  }

  @override
  TaskEither<AppFailure, Unit> clearAll() => save(const AppPreferences());
}
