import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:reactive_forms/reactive_forms.dart';

import '../../../../core/theme/app_glass_theme.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/onboarding_tokens.dart';
import '../../../../core/widgets/app_canvas.dart';
import '../../../../core/widgets/app_icon.dart';
import '../../../../core/widgets/app_page_button.dart';
import '../../../../core/widgets/pressable.dart';
import '../../../../gen/i18n/strings.g.dart';

class OnboardingLayout extends StatelessWidget {
  const OnboardingLayout({
    required this.step,
    required this.busy,
    required this.onBack,
    required this.onNext,
    required this.nextLabel,
    required this.child,
    this.onSkip,
    this.error,
    super.key,
  });
  final int step;
  final bool busy;
  final VoidCallback onBack;
  final VoidCallback onNext;
  final VoidCallback? onSkip;
  final String nextLabel;
  final String? error;
  final Widget child;

  @override
  Widget build(BuildContext context) => GlassScaffold(
    background: const AppCanvas(),
    backgroundColor: context.glass.canvasGradient.first,
    topEdgeFade: false,
    resizeToAvoidBottomInset: false,
    body: AnimatedPadding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      duration: AppMotion.duration(context, AppMotion.medium),
      curve: AppMotion.emphasized,
      onEnd: () => _revealFocus(context),
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: OnboardingTokens.maxWidth,
            ),
            child: Column(
              children: [
                _Progress(step: step, busy: busy, onBack: onBack),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) => SingleChildScrollView(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.xl),
                          child: Center(child: child),
                        ),
                      ),
                    ),
                  ),
                ),
                _Actions(
                  busy: busy,
                  onNext: onNext,
                  label: nextLabel,
                  onSkip: onSkip,
                  error: error,
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  void _revealFocus(BuildContext context) {
    // TextField's initial showOnScreen happens before the animated viewport
    // reaches its keyboard size. Reveal the whole field, including its border,
    // once the final geometry is available.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      final focused = FocusManager.instance.primaryFocus?.context;
      if (focused == null ||
          !focused.mounted ||
          focused.findAncestorWidgetOfExactType<OnboardingLayout>() == null) {
        return;
      }
      Scrollable.ensureVisible(
        focused
                .findAncestorStateOfType<
                  ReactiveFormFieldState<String, String>
                >()
                ?.context ??
            focused,
        alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
        duration: AppMotion.duration(context, AppMotion.fast),
        curve: AppMotion.emphasized,
      );
    });
  }
}

class _Progress extends StatelessWidget {
  const _Progress({
    required this.step,
    required this.busy,
    required this.onBack,
  });
  final int step;
  final bool busy;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.md,
      vertical: AppSpacing.xs,
    ),
    child: Row(
      children: [
        if (step > 0)
          Pressable(
            key: const ValueKey('onboarding-back'),
            onTap: busy ? null : onBack,
            semanticLabel: context.t.onboarding.back,
            child: const AppIcon(AppIcons.back, size: AppSizes.iconSm),
          )
        else
          const SizedBox.square(dimension: AppSizes.minTouchTarget),
        Expanded(
          child: Semantics(
            label: context.t.onboarding.progress(current: step + 1, total: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var index = 0; index < 4; index++)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xxs,
                    ),
                    child: AnimatedContainer(
                      duration: AppMotion.duration(context, AppMotion.medium),
                      width: index == step
                          ? OnboardingTokens.activeProgressWidth
                          : OnboardingTokens.progressWidth,
                      height: OnboardingTokens.progressHeight,
                      decoration: BoxDecoration(
                        color: index == step
                            ? context.glass.accent
                            : context.glass.shadowBorder,
                        borderRadius: BorderRadius.circular(
                          OnboardingTokens.progressHeight,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox.square(dimension: AppSizes.minTouchTarget),
      ],
    ),
  );
}

class _Actions extends StatelessWidget {
  const _Actions({
    required this.busy,
    required this.onNext,
    required this.label,
    required this.onSkip,
    required this.error,
  });
  final bool busy;
  final VoidCallback onNext;
  final String label;
  final VoidCallback? onSkip;
  final String? error;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(
      AppSpacing.xl,
      AppSpacing.sm,
      AppSpacing.xl,
      AppSpacing.md,
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (error case final error?) ...[
          Text(
            error,
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: Theme.of(context).colorScheme.error),
            textAlign: TextAlign.center,
          ),
          const Gap(AppSpacing.xs),
        ],
        AppPageButton(
          key: const ValueKey('onboarding-next'),
          label: label,
          icon: AppIcons.next,
          busy: busy,
          onPressed: onNext,
        ),
        if (onSkip case final onSkip?) ...[
          const Gap(AppSpacing.xxs),
          Pressable(
            key: const ValueKey('onboarding-skip'),
            onTap: busy ? null : onSkip,
            child: Text(
              context.t.onboarding.skip,
              style: Theme.of(context).textTheme.labelLarge
                  ?.copyWith(color: context.glass.foregroundMuted),
            ),
          ),
        ],
      ],
    ),
  );
}
