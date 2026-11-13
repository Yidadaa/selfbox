import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:path/path.dart' as p;
import 'package:selfbox/core/error/app_failure.dart';
import 'package:selfbox/core/storage/app_paths.dart';
import 'package:selfbox/core/storage/secret_store.dart';
import 'package:selfbox/core/testing/temp_storage.dart';
import 'package:selfbox/features/settings/data/repositories/file_ai_settings_repository.dart';
import 'package:selfbox/features/settings/data/repositories/file_app_preferences_repository.dart';
import 'package:selfbox/features/settings/domain/models/ai_settings.dart';
import 'package:selfbox/features/settings/domain/models/app_preferences.dart';

const _provider = ProviderConfig(
  id: 'p1',
  name: 'OpenAI',
  format: ApiFormat.responses,
  baseUrl: 'https://api.openai.com/v1',
);

T _ok<T>(Either<AppFailure, T> result) =>
    result.getOrElse((f) => fail('expected success, got $f'));

void main() {
  late AppPaths paths;
  late MemorySecretStore secrets;
  late FileAiSettingsRepository repo;

  setUp(() {
    paths = createTempAppPaths();
    secrets = MemorySecretStore();
    repo = FileAiSettingsRepository(paths, secrets);
  });

  group('FileAiSettingsRepository', () {
    test('clearing AI settings leaves general preferences intact', () async {
      final preferences = FileAppPreferencesRepository(paths);
      const selected = AppPreferences(theme: AppThemeChoice.dark);
      expect((await preferences.save(selected).run()).isRight(), isTrue);
      final pending = File(
        p.join(paths.root.path, 'config', 'ai_settings.json.tmp'),
      )..writeAsStringSync('interrupted');
      expect((await repo.clearAll().run()).isRight(), isTrue);
      expect(pending.existsSync(), isFalse);
      expect(
        (await preferences.load().run()).getOrElse((failure) => throw failure),
        selected,
      );
    });
    test(
      'clear removes settings and orphan credentials and is repeatable',
      () async {
        await repo.save(const AiSettings(providers: [_provider])).run();
        await repo.saveApiKey('orphan', 'secret').run();
        expect((await repo.clearAll().run()).isRight(), true);
        expect(secrets.values, isEmpty);
        expect(_ok(await repo.load().run()), const AiSettings());
        expect((await repo.clearAll().run()).isRight(), true);
      },
    );
    test('loads defaults before anything was saved', () async {
      expect(_ok(await repo.load().run()), const AiSettings());
    });

    test('saves and reloads the full document', () async {
      const settings = AiSettings(
        providers: [_provider],
        shortTermMemoryPercent: 35,
      );
      _ok(await repo.save(settings).run());

      final reloaded = FileAiSettingsRepository(paths, secrets);
      expect(_ok(await reloaded.load().run()), settings);
    });

    test('never writes API keys into the settings file', () async {
      _ok(await repo.save(const AiSettings(providers: [_provider])).run());
      _ok(await repo.saveApiKey('p1', '  sk-secret  ').run());

      final file = File(p.join(paths.root.path, 'config', 'ai_settings.json'));
      expect(file.readAsStringSync(), isNot(contains('sk-secret')));
      expect(_ok(await repo.apiKey('p1').run()), const Some('sk-secret'));
    });

    test('deleting a key removes it', () async {
      _ok(await repo.saveApiKey('p1', 'k').run());
      _ok(await repo.deleteApiKey('p1').run());
      expect(_ok(await repo.apiKey('p1').run()), const None());
    });

    test('a corrupt document is a database failure, not a crash', () async {
      final file = File(p.join(paths.root.path, 'config', 'ai_settings.json'))
        ..createSync(recursive: true)
        ..writeAsStringSync('[1, 2');
      expect(file.existsSync(), isTrue);

      expect(
        (await repo.load().run()).getLeft().toNullable(),
        isA<DatabaseFailure>(),
      );
    });

    test('watch emits the stored value and then every save', () async {
      _ok(await repo.save(const AiSettings(shortTermMemoryPercent: 21)).run());

      final seen = <int>[];
      final sub = repo.watch().listen(
        (s) => seen.add(s.shortTermMemoryPercent),
      );
      addTearDown(sub.cancel);

      await _waitFor(() => seen.isNotEmpty);
      _ok(await repo.save(const AiSettings(shortTermMemoryPercent: 22)).run());
      await _waitFor(() => seen.length >= 2);

      expect(seen, [21, 22]);
    });
  });
}

Future<void> _waitFor(bool Function() condition) async {
  for (var i = 0; i < 200 && !condition(); i++) {
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
  expect(condition(), isTrue, reason: 'condition not met in time');
}
