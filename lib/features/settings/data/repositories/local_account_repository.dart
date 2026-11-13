import 'dart:io';
import 'dart:typed_data';

import 'package:fpdart/fpdart.dart';
import 'package:luthor/luthor.dart' as lu;
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import '../../../../core/error/app_failure.dart';
import '../../../../core/storage/app_paths.dart';
import '../../../../gen/database/objectbox.g.dart';
import '../../domain/models/agent_avatar.dart';
import '../../domain/models/user_profile.dart';
import '../../domain/repositories/account_repository.dart';
import '../datasources/profile_entity.dart';

class LocalAccountRepository implements AccountRepository {
  LocalAccountRepository(Store store, this.paths)
    : _box = store.box<ProfileEntity>();
  final Box<ProfileEntity> _box;
  final AppPaths paths;

  TaskEither<AppFailure, T> _run<T>(Future<T> Function() action) =>
      TaskEither.tryCatch(
        action,
        (error, _) => AppFailure.database(message: error.toString()),
      );

  @override
  TaskEither<AppFailure, UserProfile> load() => _run(
    () async => (await _box.getAsync(1))?.toDomain() ?? const UserProfile(),
  );

  @override
  TaskEither<AppFailure, Unit> save(UserProfile profile) {
    if (ProfileSchema.nickname.validate(profile.nickname.trim())
            is lu.ValidationFailure ||
        profile.agentName.trim().length > 40) {
      return TaskEither.left(
        const AppFailure.validation(message: 'invalid nickname'),
      );
    }
    final avatar = profile.agentAvatar;
    if (avatar != null &&
        AgentAvatarPreset.fromReference(avatar) == null &&
        !(p.posix.dirname(avatar) == 'media' &&
            p.posix.basename(avatar).startsWith('avatar-'))) {
      return TaskEither.left(
        const AppFailure.validation(message: 'invalid Agent avatar'),
      );
    }
    return _run(() async {
      final previous = await _box.getAsync(1);
      await _box.putAsync(profile.toEntity());
      for (final old in [previous?.avatar, previous?.agentAvatar]) {
        if (old == null ||
            old == profile.avatar ||
            old == profile.agentAvatar) {
          continue;
        }
        // Only files created by this repository may be removed on replacement.
        if (p.posix.dirname(old) == 'media' &&
            p.posix.basename(old).startsWith('avatar-')) {
          final file = File(p.join(paths.media.path, p.posix.basename(old)));
          if (await file.exists()) await file.delete();
        }
      }
      return unit;
    });
  }

  @override
  TaskEither<AppFailure, String> importAvatar(
    Uint8List bytes,
    String extension,
  ) => _run(() async {
    final ext = extension.replaceAll('.', '').toLowerCase();
    final safeExt = RegExp(r'^[a-z0-9]+$').hasMatch(ext) ? ext : 'jpg';
    final name = 'avatar-${const Uuid().v4()}.$safeExt';
    await paths.media.create(recursive: true);
    await File(p.join(paths.media.path, name)).writeAsBytes(bytes, flush: true);
    return 'media/$name';
  });

  @override
  TaskEither<AppFailure, StorageUsage> usage() => _run(
    () async => StorageUsage(
      mediaBytes: await _size(paths.media),
      memoryBytes: await _size(paths.memory),
      databaseBytes: await _size(paths.database),
      settingsBytes: await _size(Directory(p.join(paths.root.path, 'config'))),
    ),
  );

  Future<int> _size(Directory dir) async {
    if (!await dir.exists()) return 0;
    var bytes = 0;
    await for (final entry in dir.list(recursive: true, followLinks: false)) {
      if (entry is File) bytes += (await entry.stat()).size;
    }
    return bytes;
  }

  @override
  TaskEither<AppFailure, Unit> clear() => _run(() async {
    await _box.removeAllAsync();
    if (await paths.media.exists()) await paths.media.delete(recursive: true);
    return unit;
  });
}
