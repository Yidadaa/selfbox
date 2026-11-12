import 'package:flutter/services.dart';
import 'package:fpdart/fpdart.dart';
import 'package:image_picker/image_picker.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart' as p;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/database/app_store.dart';
import '../../../../core/error/app_failure.dart';
import '../../../../core/storage/app_paths.dart';
import '../../data/repositories/local_account_repository.dart';
import '../../domain/models/user_profile.dart';
import '../../domain/repositories/account_repository.dart';

part '../../../../gen/features/settings/presentation/providers/account_providers.g.dart';

@Riverpod(keepAlive: true)
AccountRepository accountRepository(Ref ref) => LocalAccountRepository(
  ref.watch(appStoreProvider),
  ref.watch(appPathsProvider),
);

@Riverpod(keepAlive: true)
Future<UserProfile> userProfile(Ref ref) async =>
    (await ref.watch(accountRepositoryProvider).load().run()).getOrElse(
      (e) => throw e,
    );

@riverpod
Future<StorageUsage> storageUsage(Ref ref) async =>
    (await ref.watch(accountRepositoryProvider).usage().run()).getOrElse(
      (e) => throw e,
    );

@riverpod
Future<String> appVersion(Ref ref) async {
  final info = await PackageInfo.fromPlatform();
  return '${info.version} (${info.buildNumber})';
}

@riverpod
ImagePicker avatarPicker(Ref ref) => ImagePicker();

@riverpod
class ProfileController extends _$ProfileController {
  @override
  bool build() => false;

  Future<Either<AppFailure, Unit>> save(UserProfile profile) async {
    if (state) return const Right(unit);
    state = true;
    final result = await ref
        .read(accountRepositoryProvider)
        .save(profile)
        .run();
    if (ref.mounted) {
      state = false;
      if (result.isRight()) ref.invalidate(userProfileProvider);
    }
    return result;
  }

  Future<Either<AppFailure, String?>> pickAvatar() async {
    if (state) return const Right(null);
    state = true;
    final result =
        await TaskEither.tryCatch(
          () => ref
              .read(avatarPickerProvider)
              .pickImage(
                source: ImageSource.gallery,
                maxWidth: 512,
                maxHeight: 512,
                imageQuality: 85,
              ),
          _failure,
        ).flatMap((file) {
          if (file == null) return TaskEither<AppFailure, String?>.right(null);
          return TaskEither.tryCatch(file.readAsBytes, _failure).flatMap(
            (bytes) => ref
                .read(accountRepositoryProvider)
                .importAvatar(bytes, p.extension(file.name)),
          );
        }).run();
    if (ref.mounted) state = false;
    return result;
  }

  static AppFailure _failure(Object error, StackTrace _) => switch (error) {
    PlatformException(code: 'photo_access_denied') =>
      const AppFailure.permissionDenied(permission: 'photos'),
    _ => AppFailure.unexpected(error: error),
  };
}
