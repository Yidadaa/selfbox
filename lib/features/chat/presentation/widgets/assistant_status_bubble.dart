import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../core/error/app_failure.dart';
import '../../../../core/error/failure_message.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_glass_theme.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/pressable.dart';
import '../../../../gen/i18n/strings.g.dart';
import '../../domain/models/agent_activity.dart';
import '../providers/assistant_controller.dart';
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
      AssistantFailed(:final failure) => _FailureRow(
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
          alignment: Alignment.centerLeft,
          child: AnimatedSwitcher(
            duration: AppMotion.statusTransition,
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.08),
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
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(color: glass.foregroundMuted),
          ),
          const Gap(AppSpacing.xs),
          AssistantPendingIndicator(color: glass.accent),
        ],
      ),
    );
  }
}

class _FailureRow extends ConsumerWidget {
  const _FailureRow({required this.failure, super.key});

  final AppFailure failure;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t;
    final glass = context.glass;
    final error = Theme.of(context).colorScheme.error;
    final controller = ref.read(assistantControllerProvider.notifier);
    final needsSetup = switch (failure) {
      ValidationFailure(message: AppFailure.noModel) ||
      ValidationFailure(message: AppFailure.missingApiKey) => true,
      _ => false,
    };
    final text = Theme.of(context).textTheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: AssistantStatusSurface(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  size: AppSpacing.md,
                  color: error,
                ),
                const Gap(AppSpacing.xs),
                Flexible(
                  child: Text(
                    failureMessage(context, failure),
                    style: text.bodyMedium?.copyWith(
                      color: glass.onBubbleOther,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Pressable(
          onTap: needsSetup
              ? () {
                  controller.dismiss();
                  const AiProvidersRoute().go(context);
                }
              : controller.retry,
          haptic: HapticKind.light,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            child: Text(
              needsSetup ? t.assistant.setup : t.common.retry,
              style: text.labelLarge?.copyWith(color: glass.accent),
            ),
          ),
        ),
        Pressable(
          onTap: controller.dismiss,
          semanticLabel: t.assistant.dismiss,
          child: Icon(
            Icons.close_rounded,
            size: AppSpacing.lg,
            color: glass.foregroundMuted,
          ),
        ),
      ],
    );
  }
}
