import 'package:flutter/material.dart';
import 'package:flutter_smooth_markdown/flutter_smooth_markdown.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:selfbox/core/testing/app_widget_tester.dart';
import 'package:selfbox/features/chat/presentation/widgets/assistant_live_bubbles.dart';

void main() {
  testWidgets('a new reasoning segment starts with a fresh Markdown stream', (
    tester,
  ) async {
    final segment = ValueNotifier(0);
    addTearDown(segment.dispose);
    await tester.pumpPage(
      Scaffold(
        body: Center(
          child: ValueListenableBuilder<int>(
            valueListenable: segment,
            builder: (context, value, _) => AssistantThinkingBubble(
              key: ValueKey(value),
              text: value == 0 ? '# 旧步骤\n\n旧内容' : '## 新步骤\n\n**新内容**',
              fallback: '思考中',
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
    expect(
      tester.widget<SmoothMarkdown>(find.byType(SmoothMarkdown)).data,
      contains('旧内容'),
    );

    segment.value = 1;
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(
      tester.widget<SmoothMarkdown>(find.byType(SmoothMarkdown)).data,
      '## 新步骤\n\n**新内容**',
    );
    expect(tester.takeException(), isNull);
  });
}
