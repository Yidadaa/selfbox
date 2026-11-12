import 'package:objectbox/objectbox.dart';

import '../../domain/models/user_profile.dart';

@Entity()
class ProfileEntity {
  ProfileEntity({this.id = 1, required this.nickname, this.avatar});
  @Id(assignable: true)
  int id;
  String nickname;
  String? avatar;

  UserProfile toDomain() => UserProfile(nickname: nickname, avatar: avatar);
}

extension ProfileEntityMapping on UserProfile {
  ProfileEntity toEntity() =>
      ProfileEntity(nickname: nickname.trim(), avatar: avatar);
}
