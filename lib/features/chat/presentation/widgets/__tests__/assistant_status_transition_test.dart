import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:selfbox/core/error/app_failure.dart';
import 'package:selfbox/core/testing/app_widget_tester.dart';
import 'package:selfbox/core/theme/app_motion.dart';
import 'package:selfbox/core/theme/app_spacing.dart';
import 'package:selfbox/features/chat/domain/models/agent_activity.dart';
import 'package:selfbox/features/chat/domain/models/message.dart';
import 'package:selfbox/features/chat/presentation/providers/assistant_controller.dart';
import 'package:selfbox/features/chat/presentation/widgets/assistant_live_bubbles.dart';
import 'package:selfbox/features/chat/presentation/widgets/assistant_status_bubble.dart';
import 'package:selfbox/gen/i18n/strings.g.dart';

const _frame = Duration(milliseconds: 16);
const _reasoning =
    'A long reasoning passage with enough detail to occupy the '
    'whole card width.\n\n思考内容继续增长，下一步需要检索消息与记忆。';

List<AssistantState> _steps() => [
  const AssistantState.working(AgentActivity.thinking()),
  const AssistantState.working(AgentActivity.thinking(text: _reasoning)),
  for (final kind in AgentToolKind.values) ...[
    AssistantState.working(AgentActivity.tool(kind)),
    AssistantState.working(
      AgentActivity.thinking(text: _reasoning, segment: kind.index + 1),
    ),
  ],
  const AssistantState.working(AgentActivity.typing()),
  AssistantState.failed(
    const AppFailure.network(message: 'offline'),
    Message(
      id: 1,
      createdAt: kTestNow,
      author: MessageAuthor.me,
      text: 'Question',
    ),
  ),
  const AssistantState.idle(),
];

class _StatusFixture extends StatelessWidget {
  const _StatusFixture({required this.state});

  final ValueNotifier<AssistantState> state;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.bottomLeft,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: ValueListenableBuilder(
        valueListenable: state,
        builder: (_, value, _) => AssistantStatusBubble(state: value),
      ),
    ),
  );
}

void _expectLeftAnchor(WidgetTester tester, String phase) {
  for (final surface in find.byType(AssistantStatusSurface).evaluate()) {
    expect(
      tester.getTopLeft(find.byWidget(surface.widget)).dx,
      closeTo(AppSpacing.md, 0.01),
      reason: phase,
    );
  }
}

void main() {
  for (final brightness in Brightness.values) {
    for (final locale in AppLocale.values) {
      for (final width in [280.0, 390.0]) {
        testWidgets('agent stages keep one left edge in '
            '${brightness.name}/${locale.name}/$width', (tester) async {
          final stages = _steps();
          final state = ValueNotifier(stages.first);
          addTearDown(state.dispose);
          await tester.pumpPage(
            _StatusFixture(state: state),
            locale: locale,
            brightness: brightness,
            settle: false,
          );
          tester.view.physicalSize = Size(width * 3, 844 * 3);
          await tester.pump();

          for (var index = 1; index < stages.length; index++) {
            state.value = stages[index];
            await tester.pump();
            for (
              var elapsed = Duration.zero;
              elapsed <= AppMotion.statusTransition + _frame;
              elapsed += _frame
            ) {
              _expectLeftAnchor(tester, 'stage=$index time=$elapsed');
              await tester.pump(_frame);
            }
          }
          expect(find.byType(AssistantStatusSurface), findsNothing);
          expect(tester.takeException(), isNull);
        });
      }
    }
  }

  testWidgets('rapid tool and thinking replacements preserve every left edge', (
    tester,
  ) async {
    final stages = _steps();
    final state = ValueNotifier(stages[1]);
    addTearDown(state.dispose);
    await tester.pumpPage(_StatusFixture(state: state), settle: false);
    for (final next in stages.skip(2)) {
      state.value = next;
      await tester.pump();
      for (var frame = 0; frame < 5; frame++) {
        _expectLeftAnchor(tester, 'rapid frame=$frame');
        await tester.pump(_frame);
      }
    }
    await tester.pumpAndSettle();
    expect(find.byType(AssistantStatusSurface), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
