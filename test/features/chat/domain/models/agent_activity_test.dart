import 'package:flutter_test/flutter_test.dart';
import 'package:selfbox/features/chat/domain/models/agent_activity.dart';

void main() {
  test('reasoning snapshots are immutable and typing has no reply preview', () {
    const thinking = AgentThinking();
    const typing = AgentTyping();

    expect(thinking.text, isEmpty);
    expect(thinking.segment, 0);
    expect(typing, const AgentActivity.typing());
    expect(
      thinking.copyWith(text: '# 标题\n**内容**', segment: 1),
      const AgentActivity.thinking(text: '# 标题\n**内容**', segment: 1),
    );
  });
}
