import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../../../../core/theme/app_dialog_tokens.dart';
import '../../../../core/theme/app_glass_theme.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../gen/i18n/strings.g.dart';

Future<Map<String, String>?> showProviderHeadersSheet({
  required BuildContext context,
  required Map<String, String> headers,
}) => showModalBottomSheet<Map<String, String>>(
  context: context,
  isScrollControlled: true,
  backgroundColor: context.glass.bubbleOther,
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(
      top: Radius.circular(AppDialogTokens.radius),
    ),
  ),
  clipBehavior: Clip.antiAlias,
  builder: (_) => ProviderHeadersSheet(headers: headers),
);

class ProviderHeadersSheet extends HookWidget {
  const ProviderHeadersSheet({required this.headers, super.key});

  final Map<String, String> headers;

  @override
  Widget build(BuildContext context) {
    final original = headers.entries.toList(growable: false);
    final rows = useState([
      for (var index = 0; index < original.length; index++)
        _HeaderEntry(
          id: index,
          name: original[index].key,
          value: original[index].value,
        ),
    ]);
    final values = useState(<int, ({String name, String value})>{
      for (final entry in rows.value)
        entry.id: (name: entry.name, value: entry.value),
    });
    final nextId = useRef(rows.value.length);
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    final viewport = MediaQuery.sizeOf(context).height;
    final available =
        viewport - keyboard - MediaQuery.paddingOf(context).top - AppSpacing.xl;
    final height = math.max(0.0, math.min(viewport * 0.68, available));
    final headerNames = [
      for (final row in rows.value) values.value[row.id]?.name.trim() ?? '',
    ];
    final normalizedNames = headerNames
        .map((name) => name.toLowerCase())
        .toSet();
    final canSave =
        headerNames.every((name) => name.isNotEmpty) &&
        normalizedNames.length == headerNames.length;

    void update(int id, {String? name, String? value}) {
      final old = values.value[id];
      if (old == null) return;
      values.value = {
        ...values.value,
        id: (name: name ?? old.name, value: value ?? old.value),
      };
    }

    void add() {
      final id = nextId.value++;
      rows.value = [...rows.value, _HeaderEntry(id: id, name: '', value: '')];
      values.value = {...values.value, id: (name: '', value: '')};
    }

    void remove(int id) {
      rows.value = rows.value.where((row) => row.id != id).toList();
      final next = {...values.value}..remove(id);
      values.value = next;
    }

    void save() {
      final result = <String, String>{};
      for (final row in rows.value) {
        final value = values.value[row.id];
        if (value == null) continue;
        final name = value.name.trim();
        result[name] = value.value.trim();
      }
      Navigator.of(context).pop(result);
    }

    return AnimatedPadding(
      duration: AppMotion.fast,
      curve: AppMotion.emphasized,
      padding: EdgeInsets.only(bottom: keyboard),
      child: SizedBox(
        key: const ValueKey('provider-headers-sheet'),
        height: height,
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.sm,
                  AppSpacing.md,
                  AppSpacing.xs,
                ),
                child: Row(
                  children: [
                    IconButton(
                      key: const ValueKey('cancel-provider-headers'),
                      onPressed: () => Navigator.of(context).pop(),
                      tooltip: context.t.common.cancel,
                      icon: const Icon(Icons.close_rounded),
                      constraints: const BoxConstraints.tightFor(
                        width: AppSizes.minTouchTarget,
                        height: AppSizes.minTouchTarget,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        context.t.settings.provider.headers,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(color: context.glass.onBubbleOther),
                      ),
                    ),
                    TextButton(
                      key: const ValueKey('save-provider-headers'),
                      onPressed: canSave ? save : null,
                      child: Text(context.t.common.save),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: rows.value.isEmpty
                    ? EmptyState(label: context.t.settings.provider.noHeaders)
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.md,
                          AppSpacing.xs,
                          AppSpacing.md,
                          AppSpacing.md,
                        ),
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        itemCount: rows.value.length,
                        separatorBuilder: (_, _) => const Gap(AppSpacing.sm),
                        itemBuilder: (context, index) {
                          final row = rows.value[index];
                          return _HeaderRow(
                            key: ValueKey('provider-header-${row.id}'),
                            index: index,
                            name: row.name,
                            value: row.value,
                            onNameChanged: (name) => update(row.id, name: name),
                            onValueChanged: (value) =>
                                update(row.id, value: value),
                            onRemove: () => remove(row.id),
                          );
                        },
                      ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  0,
                  AppSpacing.md,
                  AppSpacing.md,
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    key: const ValueKey('add-provider-header'),
                    onPressed: add,
                    icon: const Icon(Icons.add_rounded),
                    label: Text(context.t.settings.provider.addHeader),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(
                        AppSizes.minTouchTarget,
                      ),
                      shape: const LiquidRoundedSuperellipse(
                        borderRadius: AppRadius.pill,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderRow extends HookWidget {
  const _HeaderRow({
    required this.index,
    required this.name,
    required this.value,
    required this.onNameChanged,
    required this.onValueChanged,
    required this.onRemove,
    super.key,
  });

  final int index;
  final String name;
  final String value;
  final ValueChanged<String> onNameChanged;
  final ValueChanged<String> onValueChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final nameController = useTextEditingController(text: name);
    final valueController = useTextEditingController(text: value);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: GlassTextField(
            controller: nameController,
            placeholder: context.t.settings.provider.headerName,
            surfaceStyle: GlassSurfaceStyle.solid,
            shape: const LiquidRoundedSuperellipse(borderRadius: AppRadius.sm),
            onChanged: onNameChanged,
          ),
        ),
        const Gap(AppSpacing.xs),
        Expanded(
          child: GlassTextField(
            controller: valueController,
            placeholder: context.t.settings.provider.headerValue,
            surfaceStyle: GlassSurfaceStyle.solid,
            shape: const LiquidRoundedSuperellipse(borderRadius: AppRadius.sm),
            onChanged: onValueChanged,
          ),
        ),
        IconButton(
          key: ValueKey('remove-provider-header-$index'),
          onPressed: onRemove,
          tooltip: context.t.settings.provider.removeHeader,
          icon: const Icon(Icons.remove_circle_outline_rounded),
          constraints: const BoxConstraints.tightFor(
            width: AppSizes.minTouchTarget,
            height: AppSizes.minTouchTarget,
          ),
        ),
      ],
    );
  }
}

class _HeaderEntry {
  const _HeaderEntry({
    required this.id,
    required this.name,
    required this.value,
  });

  final int id;
  final String name;
  final String value;
}
