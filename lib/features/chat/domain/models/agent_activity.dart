import 'package:freezed_annotation/freezed_annotation.dart';

part '../../../../gen/features/chat/domain/models/agent_activity.freezed.dart';

/// Coarse category of a tool call, enough to tell the user what the agent
/// is doing without exposing every step.
enum AgentToolKind {
  searchMessages,
  readMessages,
  viewImage,
  readMemory,
  writeMemory;

  static AgentToolKind? ofTool(String toolName) => switch (toolName) {
    'search_messages' => AgentToolKind.searchMessages,
    'read_messages' => AgentToolKind.readMessages,
    'view_image' => AgentToolKind.viewImage,
    'memory_list' ||
    'memory_read' ||
    'memory_search' => AgentToolKind.readMemory,
    'memory_create' ||
    'memory_patch' ||
    'memory_delete' => AgentToolKind.writeMemory,
    _ => null,
  };
}

/// What the assistant is doing right now. Only the latest activity is shown.
@freezed
sealed class AgentActivity with _$AgentActivity {
  const factory AgentActivity.thinking() = AgentThinking;

  const factory AgentActivity.tool(AgentToolKind kind) = AgentUsingTool;

  /// The final answer is being written; it is shown only once complete.
  const factory AgentActivity.typing() = AgentTyping;
}
