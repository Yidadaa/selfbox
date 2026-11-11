import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:path/path.dart' as p;
import 'package:selfbox/core/error/app_failure.dart';
import 'package:selfbox/core/storage/app_paths.dart';
import 'package:selfbox/core/storage/secret_store.dart';
import 'package:selfbox/core/testing/temp_storage.dart';
import 'package:selfbox/features/settings/data/repositories/file_ai_settings_repository.dart';
import 'package:selfbox/features/settings/domain/models/ai_settings.dart';

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
    test('loads defaults before anything was saved', () async {
      expect(_ok(await repo.load().run()), const AiSettings());
    });

    test('saves and reloads the full document', () async {
      const settings = AiSettings(providers: [_provider], historyTurns: 5);
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
      _ok(await repo.save(const AiSettings(historyTurns: 1)).run());

      final seen = <int>[];
      final sub = repo.watch().listen((s) => seen.add(s.historyTurns));
      addTearDown(sub.cancel);

      await _waitFor(() => seen.isNotEmpty);
      _ok(await repo.save(const AiSettings(historyTurns: 2)).run());
      await _waitFor(() => seen.length >= 2);

      expect(seen, [1, 2]);
    });
  });
}

Future<void> _waitFor(bool Function() condition) async {
  for (var i = 0; i < 200 && !condition(); i++) {
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
  expect(condition(), isTrue, reason: 'condition not met in time');
}
