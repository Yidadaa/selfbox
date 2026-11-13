import '../../../../core/widgets/app_artwork.dart';
import '../../../../gen/i18n/strings.g.dart';
import '../../domain/models/agent_avatar.dart';

extension AgentAvatarPresentation on AgentAvatarPreset {
  BrandArt get artwork => switch (this) {
    AgentAvatarPreset.avatar => BrandArt.avatar,
    AgentAvatarPreset.working => BrandArt.working,
    AgentAvatarPreset.playing => BrandArt.playing,
    AgentAvatarPreset.sleeping => BrandArt.sleeping,
    AgentAvatarPreset.resting => BrandArt.resting,
    AgentAvatarPreset.reading => BrandArt.reading,
    AgentAvatarPreset.awake => BrandArt.awake,
  };

  String label(Translations t) => switch (this) {
    AgentAvatarPreset.avatar => t.me.avatarPresets.defaultAvatar,
    AgentAvatarPreset.working => t.me.avatarPresets.working,
    AgentAvatarPreset.playing => t.me.avatarPresets.playing,
    AgentAvatarPreset.sleeping => t.me.avatarPresets.sleeping,
    AgentAvatarPreset.resting => t.me.avatarPresets.resting,
    AgentAvatarPreset.reading => t.me.avatarPresets.reading,
    AgentAvatarPreset.awake => t.me.avatarPresets.awake,
  };
}
