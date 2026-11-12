import 'dart:convert';
import 'dart:io';

import 'package:fpdart/fpdart.dart';
import 'package:path/path.dart' as p;

import '../../../../core/error/app_failure.dart';
import '../../../../core/storage/app_paths.dart';
import '../../domain/models/app_preferences.dart';
import '../../domain/repositories/app_preferences_repository.dart';

class FileAppPreferencesRepository implements AppPreferencesRepository {
  FileAppPreferencesRepository(AppPaths paths)
    : _file = File(p.join(paths.root.path, 'config', 'ui_preferences.json'));

  final File _file;

  static AppFailure _failure(Object error, StackTrace _) =>
      AppFailure.database(message: error.toString());

  @override
  TaskEither<AppFailure, AppPreferences> load() => TaskEither.tryCatch(
    () async {
      if (!await _file.exists()) return const AppPreferences();
      final json = jsonDecode(await _file.readAsString());
      if (json is! Map<String, dynamic>) {
        throw const AppFailure.database(message: 'corrupt ui_preferences.json');
      }
      return AppPreferences.fromJson(json);
    },
    _failure,
  );

  @override
  TaskEither<AppFailure, Unit> save(AppPreferences preferences) =>
      TaskEither.tryCatch(() async {
        await _file.parent.create(recursive: true);
        final temp = File('${_file.path}.tmp');
        await temp.writeAsString(
          const JsonEncoder.withIndent('  ').convert(preferences.toJson()),
          flush: true,
        );
        await temp.rename(_file.path);
        return unit;
      }, _failure);

  @override
  TaskEither<AppFailure, Unit> clearAll() => TaskEither.tryCatch(() async {
    if (await _file.exists()) await _file.delete();
    final temp = File('${_file.path}.tmp');
    if (await temp.exists()) await temp.delete();
    return unit;
  }, _failure);
}
