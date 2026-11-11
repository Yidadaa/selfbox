import 'package:ai_sdk_dart/ai_sdk_dart.dart';

import '../../../memory/domain/models/memory.dart';
import '../models/message.dart';

/// System instructions for AI mode.
String buildAgentInstructions({
  required DateTime now,
  required List<MemoryEntry> memory,
  required bool canViewImages,
}) {
  final index = memory.isEmpty
      ? '(empty — nothing remembered yet)'
      : memory.map((e) => '- ${e.path.value} — ${e.title}').join('\n');
  return '''
You are the assistant inside Selfbox, a private notebook where the user writes
short notes to themself like messages in a chat. Most messages are not
addressed to you. You are only called when the user switches on AI mode; the
last user message is the question to answer.

Current local time: ${_stamp(now)}.

# Notes
- The conversation history shows the most recent notes. Each user note starts
  with "[#id time]". Older notes are reachable only through your tools:
  search_messages to find, read_messages for full text and context${canViewImages ? ', view_image to look at attached pictures' : ''}.
- Search before saying something is not in the notes. Quote dates and details
  from the notes rather than guessing.

# Memory
You keep a long-term memory as markdown files and maintain it on your own:
- user/profile.md — who the user is (name, city, work, people).
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
Reply in the user's language, briefly and concretely, using markdown only when
it helps (lists, bold). Do not narrate your tool use.
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
    final text = switch (message.author) {
      MessageAuthor.me => _userLine(message),
      MessageAuthor.ai => message.text,
    };
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

/// Rough token estimate (≈3 chars per token for mixed CJK/Latin text) used
/// to keep the request within the model's input budget.
int estimateTokens(String text) => (text.length / 3).ceil();

/// Drops the oldest notes until instructions plus history fit [budget].
/// The newest note (the question) is always kept.
List<Message> fitHistory(
  List<Message> newestFirst, {
  required int budget,
  required String instructions,
}) {
  var remaining = budget - estimateTokens(instructions);
  final kept = <Message>[];
  for (final (i, message) in newestFirst.indexed) {
    final cost = estimateTokens(_userLine(message)) + 8;
    if (i > 0 && cost > remaining) break;
    kept.add(message);
    remaining -= cost;
  }
  return kept;
}

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
