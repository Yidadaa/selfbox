import 'package:flutter_smooth_markdown/flutter_smooth_markdown.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:selfbox/core/theme/sdk_material.dart';
import 'package:selfbox/features/chat/presentation/widgets/assistant_live_bubbles.dart';

import '../../../../support/app_widget_tester.dart';

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
      settle: false,
    );
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('思考中'), findsOneWidget);
    expect(find.byKey(const ValueKey('thinking-viewport')), findsOneWidget);
    expect(find.byKey(const ValueKey('pending-dot-0')), findsNothing);
    expect(
      find.byKey(const ValueKey('assistant-pending-surface')),
      findsNothing,
    );
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

  testWidgets('an empty reasoning segment shows pending chrome', (
    tester,
  ) async {
    await tester.pumpPage(
      const Scaffold(
        body: Center(
          child: AssistantThinkingBubble(text: '', fallback: '思考中'),
        ),
      ),
      settle: false,
    );

    expect(find.text('思考中'), findsOneWidget);
    expect(find.byKey(const ValueKey('pending-dot-0')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('assistant-pending-surface')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('thinking-viewport')), findsNothing);
    await tester.pump();
    final dot = find.byKey(const ValueKey('pending-dot-0'));
    final before = tester.widget<Transform>(dot).transform.getTranslation().y;
    await tester.pump(const Duration(milliseconds: 420));
    expect(
      tester.widget<Transform>(dot).transform.getTranslation().y,
      isNot(before),
    );
  });
  testWidgets(
    'pending dots stop without a ticker and resume when motion is enabled',
    (tester) async {
      final disabled = ValueNotifier(false);
      addTearDown(disabled.dispose);
      await tester.pumpPage(
        ValueListenableBuilder(
          valueListenable: disabled,
          builder: (_, value, child) => MediaQuery(
            data: MediaQueryData(disableAnimations: value),
            child: child!,
          ),
          child: const AssistantTypingBubble(label: 'Typing'),
        ),
        settle: false,
      );
      expect(tester.binding.hasScheduledFrame, isTrue);
      await tester.pump();
      final dot = find.byKey(const ValueKey('typing-dot-0'));
      final before = tester.widget<Transform>(dot).transform.getTranslation().y;
      await tester.pump(const Duration(milliseconds: 420));
      expect(
        tester.widget<Transform>(dot).transform.getTranslation().y,
        isNot(before),
      );
      disabled.value = true;
      await tester.pumpAndSettle();
      expect(tester.binding.hasScheduledFrame, isFalse);
      for (var i = 0; i < 3; i++) {
        final transform = tester.widget<Transform>(
          find.byKey(ValueKey('typing-dot-$i')),
        );
        expect(transform.transform.getTranslation().y, 0);
      }
      disabled.value = false;
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 180));
      expect(tester.binding.hasScheduledFrame, isTrue);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
