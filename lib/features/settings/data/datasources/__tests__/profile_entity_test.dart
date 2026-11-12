import 'package:flutter_test/flutter_test.dart';
import 'package:selfbox/features/settings/data/datasources/profile_entity.dart';
import 'package:selfbox/features/settings/domain/models/user_profile.dart';

void main() {
  test('profile mapping retains avatar and trims nickname', () {
    const profile = UserProfile(
      nickname: ' Flynn ',
      avatar: 'media/avatar.png',
    );
    expect(profile.toEntity().toDomain(), profile.copyWith(nickname: 'Flynn'));
    expect(profile.toEntity().id, 1);
    expect(const UserProfile().toEntity().toDomain(), const UserProfile());
  });
}
