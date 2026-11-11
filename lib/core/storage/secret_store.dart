import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fpdart/fpdart.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../error/app_failure.dart';

part '../../gen/core/storage/secret_store.g.dart';

/// Credentials (API keys) kept out of the plain settings file, in the
/// platform keychain / keystore.
abstract interface class SecretStore {
  TaskEither<AppFailure, Option<String>> read(String key);

  TaskEither<AppFailure, Unit> write(String key, String value);

  TaskEither<AppFailure, Unit> delete(String key);
}

class KeychainSecretStore implements SecretStore {
  const KeychainSecretStore([this._storage = const FlutterSecureStorage()]);

  final FlutterSecureStorage _storage;

  static AppFailure _failure(Object error, StackTrace _) =>
      AppFailure.unexpected(error: error);

  @override
  TaskEither<AppFailure, Option<String>> read(String key) =>
      TaskEither.tryCatch(
        () async => Option.fromNullable(await _storage.read(key: key)),
        _failure,
      );

  @override
  TaskEither<AppFailure, Unit> write(String key, String value) =>
      TaskEither.tryCatch(() async {
        await _storage.write(key: key, value: value);
        return unit;
      }, _failure);

  @override
  TaskEither<AppFailure, Unit> delete(String key) =>
      TaskEither.tryCatch(() async {
        await _storage.delete(key: key);
        return unit;
      }, _failure);
}

/// In-memory store for tests.
class MemorySecretStore implements SecretStore {
  final values = <String, String>{};

  @override
  TaskEither<AppFailure, Option<String>> read(String key) =>
      TaskEither.right(Option.fromNullable(values[key]));

  @override
  TaskEither<AppFailure, Unit> write(String key, String value) {
    values[key] = value;
    return TaskEither.right(unit);
  }

  @override
  TaskEither<AppFailure, Unit> delete(String key) {
    values.remove(key);
    return TaskEither.right(unit);
  }
}

@Riverpod(keepAlive: true)
SecretStore secretStore(Ref ref) => const KeychainSecretStore();
