import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_list_tile.dart';
import '../../../../core/widgets/app_page_scaffold.dart';
import '../../../../gen/i18n/strings.g.dart';
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
          quality: GlassQuality.standard,
          margin: AppInsets.section,
          children: [
            AppListTile(
              icon: Icons.storage_rounded,
              title: context.t.me.storage,
              onTap: () => const StorageRoute().push<void>(context),
            ),
            AppListTile(
              icon: Icons.auto_awesome_outlined,
              title: context.t.me.providers,
              onTap: () => const AiProvidersRoute().push<void>(context),
            ),
            AppListTile(
              icon: Icons.info_outline_rounded,
              title: context.t.me.about,
              onTap: () => const AboutRoute().push<void>(context),
            ),
            AppListTile(
              icon: Icons.receipt_long_outlined,
              title: context.t.me.logs,
              onTap: () => const TalkerRoute().push<void>(context),
            ),
          ],
        ),
      ],
    ),
  );
}
