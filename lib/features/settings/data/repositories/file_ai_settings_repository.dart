import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:fpdart/fpdart.dart';
import 'package:path/path.dart' as p;

import '../../../../core/error/app_failure.dart';
import '../../../../core/storage/app_paths.dart';
import '../../../../core/storage/secret_store.dart';
import '../../domain/models/ai_settings.dart';
import '../../domain/repositories/ai_settings_repository.dart';

/// Settings as a JSON document under the app root; API keys in [SecretStore].
class FileAiSettingsRepository implements AiSettingsRepository {
  FileAiSettingsRepository(AppPaths paths, this._secrets)
    : _file = File(p.join(paths.root.path, 'config', 'ai_settings.json'));

  final File _file;
  final SecretStore _secrets;
  final _saved = StreamController<AiSettings>.broadcast();

  static String _keyFor(String providerId) => 'provider_api_key.$providerId';

  static AppFailure _failure(Object error, StackTrace _) => switch (error) {
    final AppFailure failure => failure,
    _ => AppFailure.database(message: error.toString()),
  };

  @override
  Stream<AiSettings> watch() {
    StreamSubscription<AiSettings>? saves;
    late final StreamController<AiSettings> controller;
    controller = StreamController<AiSettings>(
      onListen: () async {
        saves = _saved.stream.listen(controller.add);
        (await load().run()).match(controller.addError, controller.add);
      },
      onCancel: () async {
        await saves?.cancel();
        await controller.close();
      },
    );
    return controller.stream;
  }

  @override
  TaskEither<AppFailure, AiSettings> load() => TaskEither.tryCatch(() async {
    if (!await _file.exists()) return const AiSettings();
    final json = jsonDecode(await _file.readAsString());
    if (json is! Map<String, dynamic>) {
      throw const AppFailure.database(message: 'corrupt ai_settings.json');
    }
    return AiSettings.fromJson(json);
  }, _failure);

  @override
  TaskEither<AppFailure, Unit> save(AiSettings settings) =>
      TaskEither.tryCatch(() async {
        await _file.parent.create(recursive: true);
        // Write-then-rename so a crash mid-write never leaves half a file.
        final temp = File('${_file.path}.tmp');
        await temp.writeAsString(
          const JsonEncoder.withIndent('  ').convert(settings.toJson()),
          flush: true,
        );
        await temp.rename(_file.path);
        _saved.add(settings);
        return unit;
      }, _failure);

  @override
  TaskEither<AppFailure, Option<String>> apiKey(String providerId) =>
      _secrets.read(_keyFor(providerId));

  @override
  TaskEither<AppFailure, Unit> saveApiKey(String providerId, String apiKey) =>
      _secrets.write(_keyFor(providerId), apiKey.trim());

  @override
  TaskEither<AppFailure, Unit> deleteApiKey(String providerId) =>
      _secrets.delete(_keyFor(providerId));
}
