import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../core/error/app_failure.dart';
import '../../../../core/error/failure_message.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_glass_theme.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/pressable.dart';
import '../../../../gen/i18n/strings.g.dart';
import '../../domain/models/agent_activity.dart';
import '../providers/assistant_controller.dart';

/// The single live line for AI mode: the latest tool in use, a typing
/// indicator while the answer is written, or a failure with a way out.
/// Never a log of every step.
class AssistantStatusBubble extends ConsumerWidget {
  const AssistantStatusBubble({required this.state, super.key});

  final AssistantState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final child = switch (state) {
      AssistantIdle() => const SizedBox.shrink(),
      AssistantWorking(activity: AgentTyping()) => const _TypingDots(),
      AssistantWorking(:final activity) => _ActivityLabel(activity: activity),
      AssistantFailed(:final failure) => _FailureRow(failure: failure),
    };
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
        child: AnimatedSize(
          duration: AppMotion.fast,
          curve: AppMotion.emphasized,
          alignment: Alignment.centerLeft,
          child: AnimatedSwitcher(
            duration: AppMotion.fast,
            child: KeyedSubtree(key: ValueKey(state), child: child),
          ),
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    const round = Radius.circular(AppRadius.md);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.glass.bubbleOther,
        borderRadius: const BorderRadius.only(
          topLeft: round,
          topRight: round,
          bottomRight: round,
          bottomLeft: Radius.circular(AppRadius.xs),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: child,
      ),
    );
  }
}

class _ActivityLabel extends StatelessWidget {
  const _ActivityLabel({required this.activity});

  final AgentActivity activity;

  @override
  Widget build(BuildContext context) {
    final a = context.t.assistant;
    final glass = context.glass;
    final (icon, label) = switch (activity) {
      AgentThinking() => (Icons.auto_awesome_rounded, a.thinking),
      AgentTyping() => (Icons.edit_rounded, a.typing),
      AgentUsingTool(:final kind) => switch (kind) {
        AgentToolKind.searchMessages => (Icons.search_rounded, a.searching),
        AgentToolKind.readMessages => (Icons.chat_outlined, a.reading),
        AgentToolKind.viewImage => (Icons.image_outlined, a.viewing),
        AgentToolKind.readMemory => (Icons.auto_awesome_outlined, a.recalling),
        AgentToolKind.writeMemory => (Icons.edit_note_rounded, a.remembering),
      },
    };
    return _Bubble(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: AppSpacing.md, color: glass.accent),
          const Gap(AppSpacing.xs),
          _Pulse(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: glass.foregroundMuted),
            ),
          ),
        ],
      ),
    );
  }
}

class _TypingDots extends HookWidget {
  const _TypingDots();

  static const _dot = 7.0;
  static const _lift = 4.0;
  static const _period = Duration(milliseconds: 960);

  @override
  Widget build(BuildContext context) {
    final color = context.glass.foregroundMuted;
    // One controller drives all dots (phase-shifted): no per-dot delay
    // timers that would outlive the widget.
    final controller = useAnimationController(duration: _period);
    useEffect(() {
      controller.repeat();
      return null;
    }, [controller]);
    return Semantics(
      label: context.t.assistant.typing,
      child: _Bubble(
        child: SizedBox(
          height: AppSpacing.lg,
          child: AnimatedBuilder(
            animation: controller,
            builder: (context, _) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < 3; i++) ...[
                  if (i > 0) const Gap(AppSpacing.xxs),
                  Transform.translate(
                    offset: Offset(
                      0,
                      -_lift *
                          math.max(
                            0,
                            math.sin((controller.value - i / 6) * 2 * math.pi),
                          ),
                    ),
                    child: Container(
                      width: _dot,
                      height: _dot,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FailureRow extends ConsumerWidget {
  const _FailureRow({required this.failure});

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
          child: _Bubble(
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

/// Gentle opacity breathing for "in progress" labels; hook-owned so nothing
/// outlives the widget.
class _Pulse extends HookWidget {
  const _Pulse({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final controller = useAnimationController(duration: AppMotion.slow * 2);
    useEffect(() {
      controller.repeat(reverse: true);
      return null;
    }, [controller]);
    return FadeTransition(
      opacity: Tween<double>(begin: 0.45, end: 1).animate(controller),
      child: child,
    );
  }
}
