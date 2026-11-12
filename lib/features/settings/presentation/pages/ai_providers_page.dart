import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../../core/error/failure_message.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_glass_theme.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_list_tile.dart';
import '../../../../core/widgets/app_page_scaffold.dart';
import '../../../../gen/i18n/strings.g.dart';
import '../../domain/models/ai_settings.dart';
import '../providers/settings_providers.dart';
import '../widgets/settings_back_button.dart';
import '../widgets/settings_labels.dart';
import '../widgets/settings_load_failure.dart';

class AiProvidersPage extends ConsumerWidget {
  const AiProvidersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(aiSettingsProvider);
    return AppPageScaffold(
      title: context.t.me.providers,
      leading: const SettingsBackButton(),
      body: switch (settings) {
        AsyncData(:final value) => _SettingsList(settings: value),
        AsyncError() => SettingsLoadFailure(
          onRetry: () => ref.invalidate(aiSettingsProvider),
        ),
        AsyncLoading() => const Skeletonizer(
          child: _SettingsList(settings: AiSettings()),
        ),
      },
    );
  }
}

class _SettingsList extends ConsumerWidget {
  const _SettingsList({required this.settings});

  final AiSettings settings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t;
    final active = settings.resolvedModel;
    return ListView(
      padding: AppPageInsets.of(context),
      children: [
        GlassGroupedSection(
          margin: AppInsets.section,
          quality: GlassQuality.standard,
          header: SectionHeader(t.settings.aiSection),
          children: [
            AppListTile(
              icon: Icons.auto_awesome_outlined,
              title: t.settings.activeModel,
              value: active?.modelId ?? t.common.notSet,
              onTap: settings.enabledModels.isEmpty
                  ? null
                  : () => _pickModel(context, ref),
            ),
            AppListTile(
              icon: Icons.history_rounded,
              title: t.settings.historyTurns,
              value: '${settings.historyTurns}',
              onTap: () => _pickHistory(context, ref),
            ),
          ],
        ),
        const Gap(AppSpacing.xl),
        GlassGroupedSection(
          margin: AppInsets.section,
          quality: GlassQuality.standard,
          header: SectionHeader(t.settings.providers),
          children: [
            for (final provider in settings.providers)
              AppListTile(
                icon: Icons.dns_outlined,
                title: provider.name,
                subtitle:
                    '${provider.format.label(context)} · '
                    '${settings.modelsOf(provider.id).where((m) => m.enabled).length}',
                onTap: () => ProviderRoute(id: provider.id).push<void>(context),
              ),
            AppListTile(
              icon: Icons.add_rounded,
              title: t.settings.addProvider,
              onTap: () => const ProviderRoute().push<void>(context),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _pickModel(BuildContext context, WidgetRef ref) {
    final models = settings.enabledModels;
    final currentIndex = models.indexWhere(
      (model) => model.ref == settings.resolvedModel?.ref,
    );
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: context.glass.bubbleOther,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(34)),
      ),
      clipBehavior: Clip.antiAlias,
      builder: (_) => _SettingsPickerSheet(
        title: context.t.settings.activeModel,
        pickerKey: const ValueKey('model-picker'),
        labels: [
          for (final model in models)
            '${settings.providerOf(model.providerId)?.name ?? model.providerId} '
                '· ${model.modelId}',
        ],
        initialIndex: currentIndex < 0 ? 0 : currentIndex,
        onSave: (index) async {
          final result = await ref
              .read(aiSettingsServiceProvider)
              .selectModel(models[index].ref)
              .run();
          if (context.mounted) {
            showOutcome(context, failure: result.getLeft().toNullable());
          }
        },
      ),
    );
  }

  Future<void> _pickHistory(BuildContext context, WidgetRef ref) =>
      showModalBottomSheet<void>(
        context: context,
        backgroundColor: context.glass.bubbleOther,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(34)),
        ),
        clipBehavior: Clip.antiAlias,
        builder: (_) => _SettingsPickerSheet(
          title: context.t.settings.historyTurns,
          pickerKey: const ValueKey('history-turns-picker'),
          labels: [
            for (
              var turns = AiSettings.minHistoryTurns;
              turns <= AiSettings.maxHistoryTurns;
              turns++
            )
              '$turns',
          ],
          initialIndex: settings.historyTurns.clamp(
            AiSettings.minHistoryTurns,
            AiSettings.maxHistoryTurns,
          ),
          onSave: (index) async {
            await ref
                .read(aiSettingsServiceProvider)
                .setHistoryTurns(index)
                .run();
          },
        ),
      );
}

class _SettingsPickerSheet extends HookWidget {
  const _SettingsPickerSheet({
    required this.title,
    required this.pickerKey,
    required this.labels,
    required this.initialIndex,
    required this.onSave,
  });

  final String title;
  final Key pickerKey;
  final List<String> labels;
  final int initialIndex;
  final Future<void> Function(int index) onSave;

  @override
  Widget build(BuildContext context) {
    final selected = useState(initialIndex);
    final scrollController = useMemoized(
      () => FixedExtentScrollController(initialItem: initialIndex),
      [initialIndex],
    );
    useEffect(() => scrollController.dispose, [scrollController]);
    return SafeArea(
      top: false,
      child: SizedBox(
        height: 332,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.xs,
          ),
          child: Column(
            children: [
              Row(
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(context.t.common.cancel),
                  ),
                  Expanded(
                    child: Text(
                      title,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium
                          ?.copyWith(color: context.glass.onBubbleOther),
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      await onSave(selected.value);
                      if (context.mounted) Navigator.of(context).pop();
                    },
                    child: Text(context.t.common.save),
                  ),
                ],
              ),
              Expanded(
                child: CupertinoPicker(
                  key: pickerKey,
                  itemExtent: 44,
                  scrollController: scrollController,
                  selectionOverlay: CupertinoPickerDefaultSelectionOverlay(
                    background: context.glass.dialogActionFill,
                  ),
                  onSelectedItemChanged: (value) => selected.value = value,
                  children: [
                    for (final label in labels)
                      Center(
                        child: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                color: context.glass.onBubbleOther,
                                decoration: TextDecoration.none,
                              ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
