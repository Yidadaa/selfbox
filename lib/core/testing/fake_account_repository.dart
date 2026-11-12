import 'dart:typed_data';

import 'package:fpdart/fpdart.dart';

import '../../features/settings/domain/models/user_profile.dart';
import '../../features/settings/domain/repositories/account_repository.dart';
import '../error/app_failure.dart';

class FakeAccountRepository implements AccountRepository {
  UserProfile profile = const UserProfile();
  AppFailure? failure;
  int clears = 0;
  @override
  TaskEither<AppFailure, UserProfile> load() => TaskEither.right(profile);
  @override
  TaskEither<AppFailure, Unit> save(UserProfile value) {
    profile = value.copyWith(nickname: value.nickname.trim());
    return TaskEither.right(unit);
  }

  @override
  TaskEither<AppFailure, String> importAvatar(
    Uint8List bytes,
    String extension,
  ) => TaskEither.right('media/avatar.png');
  @override
  TaskEither<AppFailure, StorageUsage> usage() =>
      TaskEither.right(const StorageUsage(mediaBytes: 1024));
  @override
  TaskEither<AppFailure, Unit> clear() {
    clears++;
    if (failure case final error?) return TaskEither.left(error);
    profile = const UserProfile();
    return TaskEither.right(unit);
  }
}
