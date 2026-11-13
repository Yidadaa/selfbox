enum AgentAvatarPreset {
  avatar,
  working,
  playing,
  sleeping,
  resting,
  reading,
  awake;

  String get reference => 'preset:$name';

  static AgentAvatarPreset? fromReference(String? value) =>
      values.where((preset) => preset.reference == value).firstOrNull;
}
