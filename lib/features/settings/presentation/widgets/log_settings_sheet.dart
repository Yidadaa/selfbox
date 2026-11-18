import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:selfbox/core/theme/sdk_material.dart';
import 'package:talker_flutter/talker_flutter.dart';

import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_action_button.dart';
import '../../../../core/widgets/app_list_tile.dart';
import '../../../../core/widgets/app_modal_surface.dart';
import '../../../../gen/i18n/strings.g.dart';

Future<void> showLogSettings(BuildContext context, Talker talker) =>
    showAppBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _LogSettings(talker: talker),
    );

class _LogSettings extends HookWidget {
  const _LogSettings({required this.talker});
  final Talker talker;

  @override
  Widget build(BuildContext context) {
    final settings = useState(talker.settings);
    final disabledKeys = useState(talker.filter.disabledKeys.toSet());
    void configure(TalkerSettings next) {
      talker.configure(settings: next);
      settings.value = next;
    }

    final labels = context.t.logs;
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.75,
        ),
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    labels.settings,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                AppActionIconButton(
                  tooltip: context.t.common.close,
                  icon: AppIcons.close,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            AppListTile(
              title: labels.enabled,
              trailing: GlassSwitch(
                value: settings.value.enabled,
                onChanged: (value) =>
                    configure(settings.value.copyWith(enabled: value)),
              ),
            ),
            AppListTile(
              title: labels.console,
              trailing: GlassSwitch(
                value: settings.value.useConsoleLogs,
                onChanged: (value) =>
                    configure(settings.value.copyWith(useConsoleLogs: value)),
              ),
            ),
            AppListTile(
              title: labels.history,
              trailing: GlassSwitch(
                value: settings.value.useHistory,
                onChanged: (value) =>
                    configure(settings.value.copyWith(useHistory: value)),
              ),
            ),
            for (final key in talker.settings.registeredKeys)
              AppListTile(
                title: talker.settings.getTitleByKey(key),
                trailing: GlassSwitch(
                  value: !disabledKeys.value.contains(key),
                  onChanged: (enabled) {
                    final next = enabled
                        ? disabledKeys.value.difference({key})
                        : {...disabledKeys.value, key};
                    talker.configure(
                      filter: talker.filter.copyWith(
                        disabledKeys: next.toList(),
                      ),
                    );
                    disabledKeys.value = next;
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
