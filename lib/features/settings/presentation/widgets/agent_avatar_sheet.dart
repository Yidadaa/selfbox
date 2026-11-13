import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../core/error/failure_message.dart';
import '../../../../core/theme/app_dialog_tokens.dart';
import '../../../../core/theme/app_glass_theme.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_action_button.dart';
import '../../../../core/widgets/pressable.dart';
import '../../../../gen/i18n/strings.g.dart';
import '../../domain/models/agent_avatar.dart';
import '../providers/account_providers.dart';
import 'agent_avatar_preset.dart';
import 'profile_avatar.dart';

Future<String?> showAgentAvatarSheet(
  BuildContext context, {
  String? selected,
}) => showModalBottomSheet<String>(
  context: context,
  isScrollControlled: true,
  backgroundColor: context.glass.bubbleOther,
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(
      top: Radius.circular(AppDialogTokens.radius),
    ),
  ),
  clipBehavior: Clip.antiAlias,
  builder: (_) => AgentAvatarSheet(selected: selected),
);

class AgentAvatarSheet extends ConsumerWidget {
  const AgentAvatarSheet({this.selected, super.key});
  final String? selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final busy = ref.watch(profileControllerProvider);
    return SafeArea(
      top: false,
      child: SizedBox(
        height:
            MediaQuery.sizeOf(context).height *
            AppDialogTokens.avatarSheetFraction,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      context.t.me.changeAvatar,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  AppActionIconButton(
                    icon: Icons.close_rounded,
                    tooltip: context.t.common.close,
                    onPressed: busy ? null : () => context.pop(),
                  ),
                ],
              ),
              const Gap(AppSpacing.lg),
              Expanded(
                child: _AvatarGrid(
                  selected: selected,
                  busy: busy,
                  onGallery: () => _gallery(context, ref),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _gallery(BuildContext context, WidgetRef ref) async {
    final result = await ref
        .read(profileControllerProvider.notifier)
        .pickAvatar();
    if (!context.mounted) return;
    result.match((failure) => showOutcome(context, failure: failure), (path) {
      if (path != null) context.pop(path);
    });
  }
}

class _AvatarTile extends StatelessWidget {
  const _AvatarTile({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.child,
    super.key,
  });
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) => Semantics(
    selected: selected,
    child: Pressable(
      semanticLabel: label,
      onTap: onTap,
      child: ExcludeSemantics(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                child,
                if (selected)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Icon(
                      Icons.check_circle_rounded,
                      color: context.glass.accent,
                    ),
                  ),
              ],
            ),
            const Gap(AppSpacing.xs),
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    ),
  );
}

class _GalleryIcon extends StatelessWidget {
  const _GalleryIcon();

  @override
  Widget build(BuildContext context) => Container(
    width: AppSizes.avatarPickerPreview,
    height: AppSizes.avatarPickerPreview,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: context.glass.dialogActionFill,
    ),
    child: Icon(
      Icons.add_photo_alternate_outlined,
      color: context.glass.foreground,
      size: AppSizes.iconMd,
    ),
  );
}

class _AvatarGrid extends StatelessWidget {
  const _AvatarGrid({
    required this.selected,
    required this.busy,
    required this.onGallery,
  });
  final String? selected;
  final bool busy;
  final VoidCallback onGallery;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final minimum = MediaQuery.textScalerOf(context)
          .scale(AppSizes.avatarPickerTile);
      final columns =
          ((constraints.maxWidth + AppSpacing.md) / (minimum + AppSpacing.md))
              .floor()
              .clamp(2, 4);
      final width =
          (constraints.maxWidth - (columns - 1) * AppSpacing.md) / columns;
      return SingleChildScrollView(
        child: Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.lg,
          children: [
            for (final preset in AgentAvatarPreset.values)
              SizedBox(
                width: width,
                child: _AvatarTile(
                  key: ValueKey('avatar-preset-${preset.name}'),
                  label: preset.label(context.t),
                  selected:
                      (selected ?? AgentAvatarPreset.avatar.reference) ==
                      preset.reference,
                  onTap: busy ? null : () => context.pop(preset.reference),
                  child: ProfileAvatar(
                    path: preset.reference,
                    dimension: AppSizes.avatarPickerPreview,
                  ),
                ),
              ),
            SizedBox(
              width: width,
              child: _AvatarTile(
                key: const ValueKey('avatar-gallery'),
                label: context.t.me.avatarGallery,
                selected: false,
                onTap: busy ? null : onGallery,
                child: const _GalleryIcon(),
              ),
            ),
          ],
        ),
      );
    },
  );
}
