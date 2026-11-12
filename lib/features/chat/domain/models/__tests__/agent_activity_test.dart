import 'package:flutter_test/flutter_test.dart';
import 'package:selfbox/features/chat/domain/models/agent_activity.dart';

void main() {
  test('thinking and typing previews are immutable and default to empty', () {
    const thinking = AgentThinking();
    const typing = AgentTyping();

    expect(thinking.line, isEmpty);
    expect(typing.line, isEmpty);
    expect(
      thinking.copyWith(line: 'new line'),
      const AgentActivity.thinking(line: 'new line'),
    );
    expect(
      typing.copyWith(line: 'reply'),
      const AgentActivity.typing(line: 'reply'),
    );
  });
}
