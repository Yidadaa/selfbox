import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:reactive_forms/reactive_forms.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../../core/error/app_failure.dart';
import '../../../../core/error/failure_message.dart';
import '../../../../core/forms/luthor_validator.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../gen/i18n/strings.g.dart';
import '../../domain/models/user_profile.dart';
import '../providers/account_providers.dart';
import '../providers/onboarding_controller.dart';
import '../providers/settings_providers.dart';
import '../widgets/agent_avatar_sheet.dart';
import '../widgets/onboarding_layout.dart';
import '../widgets/onboarding_step.dart';
import '../widgets/onboarding_transition.dart';

class OnboardingPage extends ConsumerWidget {
  const OnboardingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => ref
      .watch(userProfileProvider)
      .when(
        data: (profile) => _OnboardingFlow(profile: profile),
        loading: () => const IgnorePointer(
          child: Skeletonizer(child: _OnboardingFlow(profile: UserProfile())),
        ),
        error: (_, _) => OnboardingLayout(
          step: 0,
          busy: false,
          onBack: () {},
          onNext: () => ref.invalidate(userProfileProvider),
          nextLabel: context.t.common.retry,
          child: Text(
            context.t.settings.errors.generic,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      );
}

class _OnboardingFlow extends HookConsumerWidget {
  const _OnboardingFlow({required this.profile});
  final UserProfile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final step = useState(OnboardingStep.welcome);
    final avatar = useState(profile.agentAvatar);
    final defaultName = context.t.me.agentDefaultName;
    final form = useMemoized(
      () => FormGroup({
        'agentName': FormControl<String>(
          value: profile.agentName.isEmpty ? defaultName : profile.agentName,
          validators: [luthorValidator(ProfileSchema.agentName)],
        ),
        'nickname': FormControl<String>(
          value: profile.nickname,
          validators: [luthorValidator(ProfileSchema.nickname)],
        ),
      }),
    );
    useEffect(() => form.dispose, [form]);
    return _OnboardingScreen(
      profile: profile,
      form: form,
      step: step,
      avatar: avatar,
      defaultName: defaultName,
    );
  }
}

class _OnboardingScreen extends ConsumerWidget {
  const _OnboardingScreen({
    required this.profile,
    required this.form,
    required this.step,
    required this.avatar,
    required this.defaultName,
  });
  final UserProfile profile;
  final FormGroup form;
  final ValueNotifier<OnboardingStep> step;
  final ValueNotifier<String?> avatar;
  final String defaultName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saving = ref.watch(onboardingControllerProvider);
    final ready = ref.watch(aiSettingsProvider).value?.resolvedModel != null;
    return PopScope(
      canPop: step.value == OnboardingStep.welcome && !saving.isLoading,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !saving.isLoading) _back(context);
      },
      child: ReactiveForm(
        formGroup: form,
        child: OnboardingLayout(
          step: step.value.index,
          busy: saving.isLoading,
          onBack: () => _back(context),
          nextLabel: switch (step.value) {
            OnboardingStep.welcome => context.t.onboarding.begin,
            OnboardingStep.identity ||
            OnboardingStep.nickname => context.t.onboarding.next,
            OnboardingStep.connect =>
              ready
                  ? context.t.onboarding.start
                  : context.t.onboarding.configure,
          },
          error: switch (saving.error) {
            final AppFailure failure => failureMessage(context, failure),
            _ => null,
          },
          onSkip: step.value == OnboardingStep.connect && !ready
              ? () => _finish(context, ref)
              : null,
          onNext: () => _advance(context, ready, () => _finish(context, ref)),
          child: AbsorbPointer(
            absorbing: saving.isLoading,
            child: OnboardingTransition(
              child: OnboardingStepContent(
                key: ValueKey('onboarding-step-${step.value.index}'),
                step: step.value,
                nickname: (form.control('nickname').value as String).trim(),
                avatar: avatar.value,
                onAvatar: () => _pick(context, avatar),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _back(BuildContext context) {
    if (step.value == OnboardingStep.welcome) return;
    FocusScope.of(context).unfocus();
    step.value = OnboardingStep.values[step.value.index - 1];
  }

  void _finish(BuildContext context, WidgetRef ref) {
    FocusScope.of(context).unfocus();
    final name = (form.control('agentName').value as String).trim();
    ref
        .read(onboardingControllerProvider.notifier)
        .complete(
          profile.copyWith(
            agentName: profile.agentName.isEmpty && name == defaultName
                ? ''
                : name,
            nickname: (form.control('nickname').value as String).trim(),
            agentAvatar: avatar.value,
          ),
        );
  }

  void _advance(BuildContext context, bool ready, VoidCallback finish) {
    final field = switch (step.value) {
      OnboardingStep.identity => 'agentName',
      OnboardingStep.nickname => 'nickname',
      OnboardingStep.welcome || OnboardingStep.connect => null,
    };
    if (field != null) {
      final control = form.control(field);
      control.updateValue((control.value as String).trim());
      control.markAsTouched();
      if (!control.valid) return;
    }
    FocusScope.of(context).unfocus();
    if (step.value == OnboardingStep.connect) {
      if (ready) {
        finish();
      } else {
        const OnboardingAiRoute().push<void>(context);
      }
      return;
    }
    step.value = OnboardingStep.values[step.value.index + 1];
  }

  Future<void> _pick(
    BuildContext context,
    ValueNotifier<String?> avatar,
  ) async {
    FocusScope.of(context).unfocus();
    final selected = await showAgentAvatarSheet(
      context,
      selected: avatar.value,
    );
    if (context.mounted && selected != null) avatar.value = selected;
  }
}
