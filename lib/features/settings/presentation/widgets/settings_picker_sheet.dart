import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../../../../core/theme/app_dialog_tokens.dart';
import '../../../../core/theme/app_glass_theme.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_action_button.dart';
import '../../../../gen/i18n/strings.g.dart';

Future<void> showSettingsPicker({
  required BuildContext context,
  required String title,
  required Key pickerKey,
  required List<String> labels,
  required int initialIndex,
  required Future<bool> Function(int index) onSave,
}) => showModalBottomSheet<void>(
  context: context,
  backgroundColor: context.glass.bubbleOther,
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(
      top: Radius.circular(AppDialogTokens.radius),
    ),
  ),
  clipBehavior: Clip.antiAlias,
  builder: (_) => SettingsPickerSheet(
    title: title,
    pickerKey: pickerKey,
    labels: labels,
    initialIndex: initialIndex,
    onSave: onSave,
  ),
);

class SettingsPickerSheet extends HookWidget {
  const SettingsPickerSheet({
    required this.title,
    required this.pickerKey,
    required this.labels,
    required this.initialIndex,
    required this.onSave,
    super.key,
  });

  final String title;
  final Key pickerKey;
  final List<String> labels;
  final int initialIndex;
  final Future<bool> Function(int index) onSave;

  @override
  Widget build(BuildContext context) {
    final selected = useState(initialIndex);
    final saving = useState(false);
    final scrollController = useMemoized(
      () => FixedExtentScrollController(initialItem: initialIndex),
      [initialIndex],
    );
    useEffect(() => scrollController.dispose, [scrollController]);
    return SafeArea(
      top: false,
      child: SizedBox(
        height: AppDialogTokens.pickerHeight,
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
                  AppActionButton(
                    expand: false,
                    onPressed: saving.value
                        ? null
                        : () => Navigator.of(context).pop(),
                    label: context.t.common.cancel,
                  ),
                  Expanded(
                    child: Text(
                      title,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium
                          ?.copyWith(color: context.glass.onBubbleOther),
                    ),
                  ),
                  AppActionButton(
                    expand: false,
                    variant: AppActionButtonVariant.primary,
                    onPressed: saving.value
                        ? null
                        : () async {
                            saving.value = true;
                            final saved = await onSave(selected.value);
                            if (!context.mounted) return;
                            if (saved) {
                              Navigator.of(context).pop();
                            } else {
                              saving.value = false;
                            }
                          },
                    label: context.t.common.save,
                  ),
                ],
              ),
              Expanded(
                child: CupertinoPicker(
                  key: pickerKey,
                  itemExtent: AppDialogTokens.pickerItemExtent,
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
