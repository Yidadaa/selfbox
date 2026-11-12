import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_glass_theme.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../gen/i18n/strings.g.dart';
import '../providers/account_providers.dart';
import 'profile_avatar.dart';

class ProfileHeader extends ConsumerWidget {
  const ProfileHeader({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider);
    final nickname = profile.value?.nickname ?? '';
    return Skeletonizer(
      enabled: profile.isLoading,
      child: Column(
        children: [
          ProfileAvatar(path: profile.value?.avatar),
          const Gap(AppSpacing.md),
          Text(
            nickname.isEmpty ? context.t.me.defaultName : nickname,
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const Gap(AppSpacing.xs),
          GlassButton.custom(
            height: AppSizes.minTouchTarget,
            width: AppSizes.profileActionWidth,
            shape: const LiquidRoundedSuperellipse(
              borderRadius: AppRadius.pill,
            ),
            quality: GlassQuality.standard,
            onTap:
                profile.hasError
                    ? () => ref.invalidate(userProfileProvider)
                    : () => const ProfileRoute().push<void>(context),
            child: Text(
              profile.hasError
                  ? context.t.common.retry
                  : context.t.me.editProfile,
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(color: context.glass.foreground),
            ),
          ),
        ],
      ),
    );
  }
}
