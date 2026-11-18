import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:selfbox/core/theme/sdk_material.dart';

import '../../../../core/forms/glass_reactive_text_field.dart';
import '../../../../core/theme/app_glass_theme.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/onboarding_tokens.dart';
import '../../../../core/widgets/app_artwork.dart';
import '../../../../core/widgets/app_icon.dart';
import '../../../../core/widgets/pressable.dart';
import '../../../../gen/i18n/strings.g.dart';
import '../providers/settings_providers.dart';
import 'profile_avatar.dart';

enum OnboardingStep { welcome, identity, nickname, connect }

class OnboardingStepContent extends ConsumerWidget {
  const OnboardingStepContent({
    required this.step,
    required this.avatar,
    required this.onAvatar,
    required this.nickname,
    super.key,
  });
  final String nickname;
  final OnboardingStep step;
  final String? avatar;
  final VoidCallback onAvatar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _Illustration(step: step, avatar: avatar, onAvatar: onAvatar),
        const Gap(AppSpacing.xl),
        _Heading(step: step, nickname: nickname),
        if (step == OnboardingStep.identity ||
            step == OnboardingStep.nickname) ...[
          const Gap(AppSpacing.xxl),
          switch (step) {
            OnboardingStep.identity => GlassReactiveTextField<String>(
              formControlName: 'agentName',
              label: context.t.me.agentName,
            ),
            OnboardingStep.nickname => GlassReactiveTextField<String>(
              formControlName: 'nickname',
              label: context.t.me.callMe,
            ),
            OnboardingStep.connect => const SizedBox.shrink(),
            OnboardingStep.welcome => const SizedBox.shrink(),
          },
        ],
      ],
    );
  }
}

class _Illustration extends ConsumerWidget {
  const _Illustration({
    required this.step,
    required this.avatar,
    required this.onAvatar,
  });
  final OnboardingStep step;
  final String? avatar;
  final VoidCallback onAvatar;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (step == OnboardingStep.identity) {
      return _Avatar(avatar: avatar, onTap: onAvatar);
    }
    final compact = MediaQuery.viewInsetsOf(context).bottom > 0;
    final art = switch (step) {
      OnboardingStep.welcome => BrandArt.welcome,
      OnboardingStep.identity => BrandArt.avatar,
      OnboardingStep.nickname => BrandArt.recorded,
      OnboardingStep.connect =>
        ref.watch(aiSettingsProvider).value?.resolvedModel == null
            ? BrandArt.working
            : BrandArt.awake,
    };
    return AnimatedContainer(
      duration: AppMotion.duration(context, AppMotion.medium),
      curve: AppMotion.emphasized,
      width: compact
          ? OnboardingTokens.compactArtwork
          : OnboardingTokens.artwork,
      height: compact
          ? OnboardingTokens.compactArtwork
          : OnboardingTokens.artwork,
      child: FittedBox(child: AppArtwork(art, size: OnboardingTokens.artwork)),
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading({required this.step, required this.nickname});
  final String nickname;
  final OnboardingStep step;
  @override
  Widget build(BuildContext context) {
    final t = context.t.onboarding;
    final title = switch (step) {
      OnboardingStep.welcome => t.welcomeTitle,
      OnboardingStep.identity => t.identityTitle,
      OnboardingStep.nickname => t.nicknameTitle,
      OnboardingStep.connect =>
        nickname.isEmpty
            ? t.connectTitleUnnamed
            : t.connectTitle(name: nickname),
    };
    final subtitle = switch (step) {
      OnboardingStep.welcome => t.welcomeSubtitle,
      OnboardingStep.identity => t.identitySubtitle,
      OnboardingStep.nickname => t.nicknameSubtitle,
      OnboardingStep.connect => t.connectSubtitle,
    };
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          header: true,
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ),
        const Gap(AppSpacing.sm),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium
              ?.copyWith(color: context.glass.foregroundMuted),
        ),
      ],
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.avatar, required this.onTap});
  final String? avatar;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Pressable(
    key: const ValueKey('onboarding-avatar'),
    semanticLabel: context.t.me.changeAvatar,
    onTap: onTap,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          children: [
            ProfileAvatar(path: avatar, dimension: OnboardingTokens.avatar),
            Positioned(
              right: 0,
              bottom: 0,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: context.glass.bubbleOther,
                ),
                child: const Padding(
                  padding: EdgeInsets.all(AppSpacing.xs),
                  child: AppIcon(AppIcons.edit, size: AppSizes.iconSm),
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}
