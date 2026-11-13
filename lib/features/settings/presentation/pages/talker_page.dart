import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:talker_flutter/talker_flutter.dart';

import '../../../../core/logger/talker_provider.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_icon.dart';
import '../../../../core/widgets/app_page_scaffold.dart';
import '../../../../gen/i18n/strings.g.dart';
import '../widgets/log_actions_sheet.dart';
import '../widgets/log_entry_tile.dart';
import '../widgets/log_settings_sheet.dart';
import '../widgets/settings_back_button.dart';

class TalkerPage extends HookConsumerWidget {
  const TalkerPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final talker = ref.watch(talkerProvider);
    final query = useState('');
    final keys = useState(const <String>{});
    final reversed = useState(true);
    final expanded = useState(true);
    final revision = useState(0);
    return TalkerBuilder(
      talker: talker,
      builder: (context, history) {
        final matches = history
            .where(
              (entry) =>
                  (keys.value.isEmpty || keys.value.contains(entry.key)) &&
                  entry.generateTextMessage().toLowerCase().contains(
                    query.value.toLowerCase(),
                  ),
            )
            .toList();
        final rows = reversed.value ? matches.reversed.toList() : matches;
        return AppPageScaffold(
          title: context.t.me.logs,
          leading: const SettingsBackButton(),
          actions: [
            GlassIconButton(
              icon: const AppIcon(AppIcons.settings),
              semanticLabel: context.t.logs.settings,
              onPressed: () => showLogSettings(context, talker),
            ),
            GlassIconButton(
              key: const ValueKey('log-actions'),
              icon: const AppIcon(AppIcons.more),
              semanticLabel: context.t.logs.actions,
              onPressed: () => showLogActions(
                context,
                talker: talker,
                filtered: matches,
                expanded: expanded.value,
                onReverse: () => reversed.value = !reversed.value,
                onExpand: () => expanded.value = !expanded.value,
                onClear: () {
                  talker.cleanHistory();
                  revision.value++;
                },
              ),
            ),
          ],
          body: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: AppPageInsets.of(context),
                sliver: SliverList.list(
                  children: [
                    GlassTextField(
                      placeholder: context.t.logs.search,
                      prefixIcon: const AppIcon(AppIcons.search),
                      onChanged: (value) => query.value = value,
                    ),
                    const Gap(AppSpacing.xs),
                    _LogFilters(
                      talker: talker,
                      history: history,
                      selected: keys.value,
                      onSelect: (key) => keys.value = keys.value.contains(key)
                          ? keys.value.difference({key})
                          : {...keys.value, key},
                    ),
                  ],
                ),
              ),
              if (rows.isEmpty)
                SliverToBoxAdapter(
                  child: Center(child: Text(context.t.logs.empty)),
                ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                sliver: SliverList.builder(
                  itemCount: rows.length,
                  itemBuilder: (context, index) => LogEntryTile(
                    key: ObjectKey(rows[index]),
                    data: rows[index],
                    expanded: expanded.value,
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: Gap(AppSpacing.xl)),
            ],
          ),
        );
      },
    );
  }
}

class _LogFilters extends StatelessWidget {
  const _LogFilters({
    required this.talker,
    required this.history,
    required this.selected,
    required this.onSelect,
  });
  final Talker talker;
  final List<TalkerData> history;
  final Set<String> selected;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(
      children: [
        for (final key
            in history.map((entry) => entry.key).whereType<String>().toSet())
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.xs),
            child: GlassButton.custom(
              onTap: () => onSelect(key),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xs),
                child: Row(
                  children: [
                    if (selected.contains(key)) ...[
                      const AppIcon(AppIcons.success, size: AppSpacing.md),
                      const Gap(AppSpacing.xxs),
                    ],
                    Text(
                      '${talker.settings.getTitleByKey(key)} · ${history.where((entry) => entry.key == key).length}',
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
