import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:selfbox/core/theme/sdk_material.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_effects.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_list_tile.dart';
import '../../../../core/widgets/app_page_scaffold.dart';
import '../../../../gen/i18n/strings.g.dart';
import '../providers/app_preferences_controller.dart';
import '../widgets/profile_header.dart';

class MePage extends ConsumerWidget {
  const MePage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => AppPageScaffold(
    title: context.t.me.title,
    body: ListView(
      padding: AppPageInsets.of(context),
      children: [
        const Gap(AppSpacing.xl),
        const ProfileHeader(),
        const Gap(AppSpacing.xxl),
        GlassGroupedSection(
          quality: AppEffects.qualityOf(context, GlassQuality.standard),
          shape: const LiquidRoundedSuperellipse(borderRadius: AppRadius.lg),
          margin: AppInsets.section,
          children: [
            AppListTile(
              icon: AppIcons.preferences,
              title: context.t.me.general,
              onTap: () => const GeneralRoute().push<void>(context),
            ),
            AppListTile(
              icon: AppIcons.storage,
              title: context.t.me.storage,
              onTap: () => const StorageRoute().push<void>(context),
            ),
            AppListTile(
              icon: AppIcons.aiConfig,
              title: context.t.me.providers,
              onTap: () => const AiProvidersRoute().push<void>(context),
            ),
            AppListTile(
              icon: AppIcons.about,
              title: context.t.me.about,
              onTap: () => const AboutRoute().push<void>(context),
            ),
          ],
        ),
        const _DeveloperToolsSection(),
      ],
    ),
  );
}

class _DeveloperToolsSection extends ConsumerWidget {
  const _DeveloperToolsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unlocked = ref.watch(
      appPreferencesControllerProvider.select(
        (value) => value.developerToolsUnlocked,
      ),
    );
    if (!unlocked) return const SizedBox.shrink();
    return GlassGroupedSection(
      key: const ValueKey('developer-tools'),
      quality: AppEffects.qualityOf(context, GlassQuality.standard),
      shape: const LiquidRoundedSuperellipse(borderRadius: AppRadius.lg),
      margin: AppInsets.section,
      header: SectionHeader(context.t.me.developer),
      children: [
        AppListTile(
          icon: AppIcons.logs,
          title: context.t.me.logs,
          onTap: () => const TalkerRoute().push<void>(context),
        ),
        AppListTile(
          icon: AppIcons.components,
          title: context.t.me.componentLibrary,
          onTap: () => const ComponentLibraryRoute().push<void>(context),
        ),
      ],
    );
  }
}
