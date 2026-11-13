import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:talker_flutter/talker_flutter.dart';

import '../../../../core/theme/app_glass_theme.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_action_button.dart';
import '../../../../core/widgets/app_icon.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/pressable.dart';
import '../../../../gen/i18n/strings.g.dart';

class LogEntryTile extends HookWidget {
  const LogEntryTile({required this.data, required this.expanded, super.key});
  final TalkerData data;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final open = useState(expanded);
    useEffect(() {
      open.value = expanded;
      return null;
    }, [expanded]);
    final text = data.generateTextMessage();
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: context.glass.bubbleOther,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Pressable(
                      onTap: () => open.value = !open.value,
                      child: Row(
                        children: [
                          AppIcon(
                            open.value ? AppIcons.expanded : AppIcons.next,
                            size: AppSpacing.md,
                          ),
                          const Gap(AppSpacing.xs),
                          Expanded(
                            child: Text(
                              data.title ?? data.key ?? '',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  AppActionIconButton(
                    tooltip: context.t.common.copy,
                    icon: AppIcons.copy,
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: text));
                      if (context.mounted) {
                        AppToast.show(context, message: context.t.logs.copied);
                      }
                    },
                  ),
                ],
              ),
              if (open.value)
                SelectableText(
                  text,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
