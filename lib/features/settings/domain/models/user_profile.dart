import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:luthor/luthor.dart';

part '../../../../gen/features/settings/domain/models/user_profile.freezed.dart';

@freezed
abstract class UserProfile with _$UserProfile {
  const factory UserProfile({@Default('') String nickname, String? avatar}) =
      _UserProfile;
}

@freezed
abstract class StorageUsage with _$StorageUsage {
  const factory StorageUsage({
    @Default(0) int mediaBytes,
    @Default(0) int memoryBytes,
    @Default(0) int databaseBytes,
    @Default(0) int settingsBytes,
  }) = _StorageUsage;
  const StorageUsage._();
  int get totalBytes =>
      mediaBytes + memoryBytes + databaseBytes + settingsBytes;
}

abstract final class ProfileSchema {
  static final nickname = l.string().min(1).max(40).required();
}
