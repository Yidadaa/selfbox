import 'package:selfbox/core/theme/sdk_material.dart';

import '../../gen/i18n/strings.g.dart';
import '../theme/app_icons.dart';
import '../theme/app_popover_tokens.dart';
import 'app_action_popover.dart';

class AppSelectionPopover extends StatelessWidget {
  const AppSelectionPopover({
    required this.anchors,
    required this.items,
    this.onDelete,
    this.onCopy,
    this.radius = AppPopoverTokens.radius,
    super.key,
  });
  final TextSelectionToolbarAnchors anchors;
  final List<ContextMenuButtonItem> items;
  final VoidCallback? onDelete;
  final VoidCallback? onCopy;
  final double radius;

  @override
  Widget build(BuildContext context) => AppActionPopover(
    anchor: anchors.primaryAnchor,
    radius: radius,
    actions: [
      for (final item in items)
        if (item.type == ContextMenuButtonType.copy)
          AppPopoverAction(
            label: context.t.common.copy,
            icon: AppIcons.copy,
            onPressed: () {
              item.onPressed?.call();
              onCopy?.call();
            },
          )
        else if (item.type == ContextMenuButtonType.selectAll)
          AppPopoverAction(
            label: context.t.common.selectAll,
            icon: AppIcons.checked,
            onPressed: item.onPressed ?? () {},
          ),
      if (onDelete case final remove?)
        AppPopoverAction(
          label: context.t.common.delete,
          icon: AppIcons.delete,
          destructive: true,
          onPressed: remove,
        ),
    ],
  );
}
