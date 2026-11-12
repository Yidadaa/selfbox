import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:selfbox/core/error/app_failure.dart';
import 'package:selfbox/core/testing/temp_storage.dart';
import 'package:selfbox/features/settings/data/repositories/file_app_preferences_repository.dart';
import 'package:selfbox/features/settings/domain/models/app_preferences.dart';

void main() {
  test(
    'loads defaults, saves preferences, and reloads after restart',
    () async {
      final paths = createTempAppPaths();
      final repo = FileAppPreferencesRepository(paths);
      expect(
        (await repo.load().run()).getOrElse((failure) => throw failure),
        const AppPreferences(),
      );

      const selected = AppPreferences(
        theme: AppThemeChoice.light,
        language: AppLanguageChoice.en,
      );
      expect((await repo.save(selected).run()).isRight(), isTrue);
      final reopened = FileAppPreferencesRepository(paths);
      expect(
        (await reopened.load().run()).getOrElse((failure) => throw failure),
        selected,
      );

      const updated = AppPreferences(
        theme: AppThemeChoice.dark,
        language: AppLanguageChoice.zhCn,
      );
      expect((await reopened.save(updated).run()).isRight(), isTrue);
      expect(
        (await FileAppPreferencesRepository(
          paths,
        ).load().run()).getOrElse((failure) => throw failure),
        updated,
      );

      final pending = File(
        p.join(paths.root.path, 'config', 'ui_preferences.json.tmp'),
      )..writeAsStringSync('interrupted');

      expect((await reopened.clearAll().run()).isRight(), isTrue);
      expect(pending.existsSync(), isFalse);
      expect(
        (await repo.load().run()).getOrElse((failure) => throw failure),
        const AppPreferences(),
      );
      expect((await reopened.clearAll().run()).isRight(), isTrue);
    },
  );

  test('corrupt or unsupported preferences fail without a crash', () async {
    final paths = createTempAppPaths();
    final file = File(p.join(paths.root.path, 'config', 'ui_preferences.json'))
      ..createSync(recursive: true)
      ..writeAsStringSync('{"theme":"unknown"}');
    expect(file.existsSync(), isTrue);

    expect(
      (await FileAppPreferencesRepository(
        paths,
      ).load().run()).getLeft().toNullable(),
      isA<DatabaseFailure>(),
    );
  });
}
