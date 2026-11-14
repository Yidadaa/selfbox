import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../../../../core/theme/app_effects.dart';
import '../../../../core/theme/app_glass_theme.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/image_viewer_tokens.dart';
import '../../../../core/widgets/app_icon.dart';
import '../../../../gen/i18n/strings.g.dart';
import 'image_viewer_thumbnails.dart';

class ImageViewerChrome extends ConsumerWidget {
  const ImageViewerChrome({
    required this.paths,
    required this.selected,
    required this.controller,
    super.key,
  });
  final List<String> paths;
  final int selected;
  final PageController controller;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final insets = MediaQuery.paddingOf(context);
    return Stack(
      children: [
        if (paths.length > 1)
          Positioned(
            bottom: insets.bottom + AppSpacing.md,
            left: 0,
            right: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${selected + 1} / ${paths.length}',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: ImageViewerTokens.foreground,
                    shadows: const [ImageViewerTokens.controlShadow],
                  ),
                ),
                const Gap(AppSpacing.xs),
                ImageViewerThumbnails(
                  paths: paths,
                  selected: selected,
                  onScrub: controller.jumpToPage,
                  onSelected: (slot) {
                    if (MediaQuery.disableAnimationsOf(context)) {
                      controller.jumpToPage(slot);
                    } else {
                      controller.animateToPage(
                        slot,
                        duration: AppMotion.medium,
                        curve: AppMotion.emphasized,
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        Positioned(
          top: insets.top + AppSpacing.xs,
          left: AppInsets.pageHorizontal,
          child: const _ViewerCloseButton(),
        ),
      ],
    );
  }
}

class _ViewerCloseButton extends ConsumerWidget {
  const _ViewerCloseButton();
  @override
  Widget build(BuildContext context, WidgetRef ref) => GlassIconButton(
    key: const ValueKey('image-viewer-close'),
    // Grouped glass paints behind the photo even when the button is last in Stack.
    useOwnLayer: true,
    settings: LiquidGlassSettings(
      blur: AppGlassTheme.dark.chromeBlur,
      glassColor: AppGlassTheme.dark.chromeTint,
    ),
    quality: AppEffects.qualityOf(context, GlassQuality.premium),
    icon: AppIcon(AppIcons.close, color: ImageViewerTokens.foreground),
    semanticLabel: context.t.common.close,
    size: AppSizes.minTouchTarget,
    onPressed: () => context.pop(),
  );
}
