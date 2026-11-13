import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../../core/error/failure_message.dart';
import '../../../../core/theme/app_effects.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_artwork.dart';
import '../../../../core/widgets/app_list_tile.dart';
import '../../../../core/widgets/app_page_scaffold.dart';
import '../../../../gen/i18n/strings.g.dart';
import '../providers/account_providers.dart';
import '../providers/app_preferences_controller.dart';
import '../widgets/settings_back_button.dart';

class AboutPage extends ConsumerWidget {
  const AboutPage({super.key});

  static const _updatedOn = '2026-11-14';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final version = ref.watch(appVersionProvider);
    final labels = context.t.me;
    return AppPageScaffold(
      title: labels.about,
      leading: const SettingsBackButton(),
      body: ListView(
        padding: AppPageInsets.of(context),
        children: [
          const Gap(AppSpacing.xl),
          const Center(child: _AboutArtwork()),
          const Gap(AppSpacing.xxl),
          GlassGroupedSection(
            quality: AppEffects.qualityOf(context, GlassQuality.standard),
            shape: const LiquidRoundedSuperellipse(borderRadius: AppRadius.lg),
            margin: AppInsets.section,
            children: [
              Skeletonizer(
                enabled: version.isLoading,
                child: AppListTile(
                  icon: AppIcons.appVersion,
                  title: labels.version,
                  value: version.hasError
                      ? context.t.common.retry
                      : version.value ?? labels.version,
                  onTap: version.hasError
                      ? () => ref.invalidate(appVersionProvider)
                      : null,
                ),
              ),
              AppListTile(
                icon: AppIcons.updateDate,
                title: labels.updateDate,
                value: _updatedOn,
              ),
              AppListTile(
                icon: AppIcons.agreement,
                title: labels.userAgreement,
              ),
              AppListTile(
                icon: AppIcons.website,
                title: labels.officialWebsite,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AboutArtwork extends HookConsumerWidget {
  const _AboutArtwork();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final taps = useState(0);
    return GestureDetector(
      onTap: () async {
        taps.value++;
        if (taps.value < 5) return;
        taps.value = 0;
        final result = await ref
            .read(appPreferencesControllerProvider.notifier)
            .unlockDeveloperTools();
        if (context.mounted && result.isLeft()) {
          showOutcome(context, failure: result.getLeft().toNullable());
        }
      },
      child: const AppArtwork(BrandArt.reading),
    );
  }
}
