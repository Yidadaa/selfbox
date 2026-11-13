import 'package:ai_sdk_dart/ai_sdk_dart.dart';

import '../../../memory/domain/models/memory.dart';
import '../models/message.dart';

/// System instructions for AI mode.
String buildAgentInstructions({
  required DateTime now,
  required List<MemoryEntry> memory,
  required bool canViewImages,
  required String userName,
  required String agentName,
  required String languageTag,
}) {
  final index = memory.isEmpty
      ? '(empty — nothing remembered yet)'
      : memory.map((e) => '- ${e.path.value} — ${e.title}').join('\n');
  return '''
You are the assistant inside 小懒, a private notebook where the user writes
short notes to themself like messages in a chat. Most messages are not
addressed to you. You are only called when the user switches on AI mode; the
last user message is the question to answer.
Your name is $agentName.

Current local time: ${_stamp(now)}.
Current time zone: ${now.timeZoneName} (UTC${_offset(now.timeZoneOffset)}).
Preferred language: $languageTag.
User's current name: ${userName.isEmpty ? '(not set)' : userName}.

# Notes
- The conversation history shows the most recent notes. Each user note starts
  with "[#id time]". Older notes are reachable only through your tools:
  search_messages to find, read_messages for full text and context${canViewImages ? ', view_image to look at attached pictures' : ''}.
- Search before saying something is not in the notes. Quote dates and details
  from the notes rather than guessing.

# Memory
You keep a long-term memory as markdown files and maintain it on your own:
- user.md — the user's profile and how to address them.
- user/prefer.md — tastes, habits, how they like answers.
- topic/<kebab-case>.md — one file per ongoing subject (projects, plans,
  health, trips). Create a topic once it comes up repeatedly or matters.
Whenever the user reveals something durable (a fact, preference, decision,
plan or change to an earlier one), update memory in the same turn: read the
file, then memory_patch it with a minimal unified diff; memory_create only for
new files. Keep files short, factual and deduplicated; delete what is obsolete.
Never store secrets such as passwords or keys.

Current memory files:
$index

# Answering
Write short, natural chat messages, like a familiar friend. Use simple sentences
and the user's preferred language; address them by their current name when set.
Use markdown only when it helps (lists, bold). Do not narrate your tool use.
''';
}

/// Converts the newest-first [recent] notes into chat history, oldest first.
///
/// User notes become user turns stamped with id and time so the model can
/// cite or look them up; AI replies become assistant turns. Consecutive
/// notes from the same side are merged, and the history always starts with
/// a user turn, which some providers require.
List<ModelMessage> buildAgentHistory(List<Message> recent) {
  final ordered = recent.reversed.toList();
  final turns = <({ModelMessageRole role, List<String> parts})>[];
  for (final message in ordered) {
    final role = switch (message.author) {
      MessageAuthor.me => ModelMessageRole.user,
      MessageAuthor.ai => ModelMessageRole.assistant,
    };
    final text = _historyText(message);
    if (turns.isNotEmpty && turns.last.role == role) {
      turns.last.parts.add(text);
    } else {
      turns.add((role: role, parts: [text]));
    }
  }
  while (turns.isNotEmpty && turns.first.role != ModelMessageRole.user) {
    turns.removeAt(0);
  }
  return [
    for (final turn in turns)
      ModelMessage(role: turn.role, content: turn.parts.join('\n\n')),
  ];
}

/// Lightweight estimate: three ASCII characters, one non-ASCII BMP character,
/// or half a supplementary character per token. Count Unicode scalars so CJK
/// and emoji do not inherit the much cheaper ASCII estimate.
int estimateTokens(String text) {
  var units = 0;
  for (final rune in text.runes) {
    units += rune <= 0x7F ? 1 : (rune <= 0xFFFF ? 3 : 6);
  }
  return (units + 2) ~/ 3;
}

/// Includes the actual timestamp/attachment text and a small envelope allowance.
int estimateMessageTokens(Message message) =>
    estimateTokens(_historyText(message)) + 8;

String _historyText(Message message) => switch (message.author) {
  MessageAuthor.me => _userLine(message),
  MessageAuthor.ai => message.text,
};

String _userLine(Message m) {
  final images = m.images.isEmpty
      ? ''
      : ' [${m.images.length} image${m.images.length > 1 ? 's' : ''}]';
  final body = m.text.isEmpty ? '' : ' ${m.text}';
  return '[#${m.id} ${_stamp(m.createdAt)}]$images$body';
}

String _stamp(DateTime t) {
  final l = t.toLocal();
  String two(int v) => v.toString().padLeft(2, '0');
  return '${l.year}-${two(l.month)}-${two(l.day)} ${two(l.hour)}:${two(l.minute)}';
}

String _offset(Duration value) {
  final minutes = value.inMinutes.abs();
  final sign = value.isNegative ? '-' : '+';
  return '$sign${(minutes ~/ 60).toString().padLeft(2, '0')}:${(minutes % 60).toString().padLeft(2, '0')}';
}
