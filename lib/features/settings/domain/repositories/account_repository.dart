import 'dart:typed_data';

import 'package:fpdart/fpdart.dart';

import '../../../../core/error/app_failure.dart';
import '../models/user_profile.dart';

abstract interface class AccountRepository {
  TaskEither<AppFailure, UserProfile> load();
  TaskEither<AppFailure, Unit> save(UserProfile profile);
  TaskEither<AppFailure, String> importAvatar(
    Uint8List bytes,
    String extension,
  );
  TaskEither<AppFailure, StorageUsage> usage();
  TaskEither<AppFailure, Unit> clear();
}
