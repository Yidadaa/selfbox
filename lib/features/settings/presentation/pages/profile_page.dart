import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:reactive_forms/reactive_forms.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../../core/error/failure_message.dart';
import '../../../../core/forms/glass_reactive_text_field.dart';
import '../../../../core/forms/luthor_validator.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_page_scaffold.dart';
import '../../../../gen/i18n/strings.g.dart';
import '../../domain/models/user_profile.dart';
import '../providers/account_providers.dart';
import '../widgets/agent_avatar_sheet.dart';
import '../widgets/primary_button.dart';
import '../widgets/profile_avatar.dart';
import '../widgets/settings_back_button.dart';
import '../widgets/settings_load_failure.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider);
    return AppPageScaffold(
      title: context.t.me.editProfile,
      leading: const SettingsBackButton(),
      body: switch (profile) {
        AsyncData(:final value) => _ProfileForm(profile: value),
        AsyncLoading() => const Skeletonizer(
          child: _ProfileForm(profile: UserProfile()),
        ),
        AsyncError() => SettingsLoadFailure(
          onRetry: () => ref.invalidate(userProfileProvider),
        ),
      },
    );
  }
}

class _ProfileForm extends HookConsumerWidget {
  const _ProfileForm({required this.profile});
  final UserProfile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final busy = ref.watch(profileControllerProvider);
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
    return PopScope(
      canPop: !busy,
      child: AbsorbPointer(
        absorbing: busy,
        child: ReactiveForm(
          formGroup: form,
          child: _ProfileFields(
            avatar: avatar.value,
            busy: busy,
            onPick: () => _pick(context, avatar),
            onSave: () => _save(context, ref, form, avatar.value),
          ),
        ),
      ),
    );
  }

  Future<void> _pick(
    BuildContext context,
    ValueNotifier<String?> avatar,
  ) async {
    FocusScope.of(context).unfocus();
    final result = await showAgentAvatarSheet(context, selected: avatar.value);
    if (!context.mounted) return;
    if (result != null) avatar.value = result;
  }

  Future<void> _save(
    BuildContext context,
    WidgetRef ref,
    FormGroup form,
    String? avatar,
  ) async {
    form.markAllAsTouched();
    if (!form.valid) return;
    final result = await ref
        .read(profileControllerProvider.notifier)
        .save(
          profile.copyWith(
            nickname: form.control('nickname').value as String,
            agentName: _agentName(
              form.control('agentName').value as String,
              context.t.me.agentDefaultName,
            ),
            agentAvatar: avatar,
          ),
        );
    if (!context.mounted) return;
    if (result.getLeft().toNullable() case final failure?) {
      showOutcome(context, failure: failure);
      return;
    }
    // Allow PopScope to reflect the completed save before navigating back.
    await WidgetsBinding.instance.endOfFrame;
    if (context.mounted) context.pop();
  }

  String _agentName(String entered, String fallback) =>
      profile.agentName.isEmpty && entered.trim() == fallback
      ? ''
      : entered.trim();
}

class _ProfileFields extends StatelessWidget {
  const _ProfileFields({
    required this.avatar,
    required this.busy,
    required this.onPick,
    required this.onSave,
  });
  final String? avatar;
  final bool busy;
  final VoidCallback onPick;
  final VoidCallback onSave;
  @override
  Widget build(BuildContext context) => ListView(
    padding: AppPageInsets.of(context),
    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
    children: [
      Center(child: ProfileAvatar(path: avatar)),
      const Gap(AppSpacing.md),
      Center(
        child: GlassButton.custom(
          quality: GlassQuality.standard,
          height: AppSizes.minTouchTarget,
          width: AppSizes.profileActionWidth,
          shape: const LiquidRoundedSuperellipse(borderRadius: AppRadius.pill),
          onTap: onPick,
          child: Text(
            context.t.me.changeAvatar,
            style: Theme.of(context).textTheme.labelLarge,
          ),
        ),
      ),
      const Gap(AppSpacing.xxl),
      GlassReactiveTextField<String>(
        formControlName: 'agentName',
        label: context.t.me.agentName,
      ),
      const Gap(AppSpacing.lg),
      GlassReactiveTextField<String>(
        formControlName: 'nickname',
        label: context.t.me.callMe,
      ),
      const Gap(AppSpacing.xl),
      PrimaryButton(label: context.t.common.save, busy: busy, onTap: onSave),
    ],
  );
}
