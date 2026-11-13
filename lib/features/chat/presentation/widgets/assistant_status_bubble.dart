import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../core/theme/app_glass_theme.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../gen/i18n/strings.g.dart';
import '../../domain/models/agent_activity.dart';
import '../providers/assistant_controller.dart';
import 'assistant_failure_bubble.dart';
import 'assistant_live_bubbles.dart';

/// The current reasoning, latest tool, or a recoverable error.
class AssistantStatusBubble extends ConsumerWidget {
  const AssistantStatusBubble({required this.state, super.key});

  final AssistantState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final labels = context.t.assistant;
    final child = switch (state) {
      AssistantIdle() => const SizedBox.shrink(),
      AssistantWorking(activity: AgentThinking(:final text, :final segment)) =>
        AssistantThinkingBubble(
          key: ValueKey('thinking-$segment'),
          fallback: labels.thinking,
          text: text,
        ),
      AssistantWorking(activity: AgentTyping()) => AssistantTypingBubble(
        key: const ValueKey('typing'),
        label: labels.typing,
      ),
      AssistantWorking(activity: final AgentUsingTool activity) =>
        _ActivityLabel(key: ValueKey(activity.kind), activity: activity),
      AssistantFailed(:final failure) => AssistantFailureBubble(
        key: const ValueKey('failure'),
        failure: failure,
      ),
    };
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
        child: AnimatedSize(
          duration: AppMotion.statusTransition,
          curve: AppMotion.emphasized,
          alignment: Alignment.bottomLeft,
          child: AnimatedSwitcher(
            duration: AppMotion.statusTransition,
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            // Each stage has a different width. Centering the overlap would
            // move the next card when the wider outgoing stage disappears.
            layoutBuilder: (current, previous) => Stack(
              alignment: Alignment.bottomLeft,
              children: [...previous, ?current],
            ),
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: AppMotion.assistantStageOffset,
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _ActivityLabel extends StatelessWidget {
  const _ActivityLabel({required this.activity, super.key});

  final AgentUsingTool activity;

  @override
  Widget build(BuildContext context) {
    final a = context.t.assistant;
    final glass = context.glass;
    final (icon, label) = switch (activity.kind) {
      AgentToolKind.searchMessages => (Icons.search_rounded, a.searching),
      AgentToolKind.readMessages => (Icons.chat_outlined, a.reading),
      AgentToolKind.viewImage => (Icons.image_outlined, a.viewing),
      AgentToolKind.readMemory => (Icons.auto_awesome_outlined, a.recalling),
      AgentToolKind.writeMemory => (Icons.edit_note_rounded, a.remembering),
    };
    return AssistantStatusSurface(
      pending: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: AppSpacing.md, color: glass.accent),
          const Gap(AppSpacing.xs),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: glass.foregroundMuted),
            ),
          ),
          const Gap(AppSpacing.xs),
          AssistantPendingIndicator(color: glass.accent),
        ],
      ),
    );
  }
}
