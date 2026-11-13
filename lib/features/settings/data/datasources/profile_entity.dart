import 'package:objectbox/objectbox.dart';

import '../../domain/models/user_profile.dart';

@Entity()
class ProfileEntity {
  ProfileEntity({
    this.id = 1,
    required this.nickname,
    this.avatar,
    this.agentName = '',
    this.agentAvatar,
  });
  @Id(assignable: true)
  int id;
  String nickname;
  String? avatar;
  String agentName;
  String? agentAvatar;

  UserProfile toDomain() => UserProfile(
    nickname: nickname,
    avatar: avatar,
    agentName: agentName,
    agentAvatar: agentAvatar,
  );
}

extension ProfileEntityMapping on UserProfile {
  ProfileEntity toEntity() => ProfileEntity(
    nickname: nickname.trim(),
    avatar: avatar,
    agentName: agentName.trim(),
    agentAvatar: agentAvatar,
  );
}
