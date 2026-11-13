import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:selfbox/core/theme/app_radius.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/router/shell_scope.dart';
import '../../../../core/theme/app_glass_theme.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/time/clock.dart';
import '../../../../core/widgets/app_artwork.dart';
import '../../../../core/widgets/app_page_scaffold.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../gen/i18n/strings.g.dart';
import '../../../chat/presentation/widgets/date_labels.dart';
import '../../domain/models/memory.dart';
import '../providers/memory_providers.dart';

class MemoryPage extends ConsumerWidget {
  const MemoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final folders = ref.watch(memoryFoldersProvider);
    return AppPageScaffold(
      title: context.t.memory.title,
      body: Stack(
        children: [
          switch (folders) {
            AsyncData(:final value) => _FolderList(folders: value),
            AsyncError() => EmptyState(
              illustration: BrandArt.error,
              label: context.t.common.loadFailed,
              action: GlassButton.custom(
                height: AppSizes.minTouchTarget,
                onTap: () => ref.invalidate(memoryFoldersProvider),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xl,
                  ),
                  child: Text(
                    context.t.common.retry,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
              ),
            ),
            AsyncLoading() => Skeletonizer(
              child: _FolderList(folders: _placeholderFolders()),
            ),
          },
          Positioned(
            right: AppInsets.pageHorizontal,
            bottom: ShellScope.bottomInsetOf(context) + AppSpacing.md,
            child: GlassButton.custom(
              key: const ValueKey('add-memory'),
              shape: const LiquidRoundedSuperellipse(
                borderRadius: AppRadius.pill,
              ),
              quality: GlassQuality.premium,
              height: AppSizes.minTouchTarget,
              onTap: () => const MemoryEditorRoute().push<void>(context),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_rounded, color: context.glass.foreground),
                    const Gap(AppSpacing.xs),
                    Text(
                      context.t.memory.add,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static List<MemoryFolder> _placeholderFolders() {
    MemoryEntry entry(String path) => MemoryEntry(
      path: MemoryPath.parse(path).getOrElse((f) => throw f),
      updatedAt: DateTime(2026),
      sizeBytes: 0,
      title: 'Placeholder title',
    );
    return [
      MemoryFolder(
        name: 'user',
        entries: [entry('user/profile.md'), entry('user/prefer.md')],
      ),
    ];
  }
}

class _FolderList extends StatelessWidget {
  const _FolderList({required this.folders});

  final List<MemoryFolder> folders;

  @override
  Widget build(BuildContext context) {
    if (folders.isEmpty) {
      return Padding(
        padding: AppPageInsets.of(context).copyWith(
          bottom:
              ShellScope.bottomInsetOf(context) +
              AppSizes.minTouchTarget +
              AppSpacing.xxl,
        ),
        child: EmptyState(
          label: context.t.memory.empty,
          illustration: BrandArt.files,
        ),
      );
    }
    return ListView.separated(
      padding: AppPageInsets.of(context).copyWith(
        bottom:
            ShellScope.bottomInsetOf(context) +
            AppSizes.minTouchTarget +
            AppSpacing.xxl,
      ),
      itemCount: folders.length,
      separatorBuilder: (_, _) => const Gap(AppSpacing.lg),
      itemBuilder: (context, index) => _FolderSection(folder: folders[index]),
    );
  }
}

class _FolderSection extends ConsumerWidget {
  const _FolderSection({required this.folder});

  final MemoryFolder folder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final glass = context.glass;
    final now = ref.watch(clockProvider)();
    final t = context.t;
    final locale = LocaleSettings.currentLocale.languageTag;
    final text = Theme.of(context).textTheme;
    return GlassGroupedSection(
      margin: AppInsets.section,
      // Solid cards: these scroll, and live refraction on every list
      // section would exceed the blur budget.
      surfaceStyle: GlassSurfaceStyle.solid,
      header: Text(
        folder.name.isEmpty ? t.memory.rootFolder : folder.name,
        style: text.labelLarge?.copyWith(color: glass.foregroundMuted),
      ),
      children: [
        for (final entry in folder.entries)
          GlassListTile(
            leading: Icon(
              Icons.description_outlined,
              color: glass.foregroundMuted,
            ),
            title: Text(entry.title),
            titleStyle: text.bodyLarge?.copyWith(color: glass.foreground),
            subtitleStyle: text.bodySmall?.copyWith(
              color: glass.foregroundMuted,
            ),
            subtitle: Text(
              '${entry.path.fileName} · ${formatDayLabel(entry.updatedAt, now, locale: locale, today: t.chat.today, yesterday: t.chat.yesterday)}',
            ),
            trailing: Icon(
              Icons.chevron_right_rounded,
              color: glass.foregroundMuted,
            ),
            onTap: () =>
                MemoryFileRoute(path: entry.path.value).push<void>(context),
          ),
      ],
    );
  }
}
