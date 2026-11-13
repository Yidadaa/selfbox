import 'package:flutter_test/flutter_test.dart';
import 'package:luthor/luthor.dart';
import 'package:selfbox/features/settings/domain/models/user_profile.dart';

void main() {
  test(
    'profile is immutable and nickname validation defines form boundaries',
    () {
      const profile = UserProfile(nickname: 'Flynn', avatar: 'media/a.jpg');
      expect(
        profile,
        const UserProfile(nickname: 'Flynn', avatar: 'media/a.jpg'),
      );
      expect(profile.copyWith(avatar: null).nickname, 'Flynn');
      expect(const UserProfile().agentName, isEmpty);
      expect(const UserProfile().agentAvatar, isNull);
      expect(profile.copyWith(agentName: 'Dozy').nickname, 'Flynn');
      for (final value in ['a' * 41]) {
        expect(
          ProfileSchema.nickname.validate(value),
          isA<ValidationFailure<Object?>>(),
        );
      }
      expect(
        ProfileSchema.nickname.validate('a' * 40),
        isA<ValidationSuccess<Object?>>(),
      );
      expect(
        ProfileSchema.nickname.validate(''),
        isA<ValidationSuccess<Object?>>(),
      );
      expect(
        ProfileSchema.agentName.validate('a' * 41),
        isA<ValidationFailure<Object?>>(),
      );
      expect(
        const StorageUsage(
          mediaBytes: 2,
          memoryBytes: 3,
          databaseBytes: 4,
          settingsBytes: 5,
        ).totalBytes,
        14,
      );
    },
  );
}
