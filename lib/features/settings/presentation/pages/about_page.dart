import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../core/theme/app_artwork_tokens.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_artwork.dart';
import '../../../../core/widgets/app_page_scaffold.dart';
import '../../../../gen/i18n/strings.g.dart';
import '../providers/account_providers.dart';
import '../widgets/primary_button.dart';
import '../widgets/settings_back_button.dart';

class AboutPage extends ConsumerWidget {
  const AboutPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final version = ref.watch(appVersionProvider);
    return AppPageScaffold(
      title: context.t.me.about,
      leading: const SettingsBackButton(),
      body: ListView(
        padding: AppPageInsets.of(context),
        children: [
          const Gap(AppSpacing.xxl),
          const Center(
            child: AppArtwork(BrandArt.logo, size: AppArtworkTokens.logo),
          ),
          const Gap(AppSpacing.xl),
          Text(
            context.t.app.name,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const Gap(AppSpacing.sm),
          if (version.hasError)
            PrimaryButton(
              label: context.t.common.retry,
              onTap: () => ref.invalidate(appVersionProvider),
            )
          else
            Text(
              version.value ?? context.t.me.version,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          const Gap(AppSpacing.xl),
          Text(
            context.t.me.tagline,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }
}
