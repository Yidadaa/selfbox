import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
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
import '../../data/chat_data_providers.dart';
import '../widgets/image_viewer_image.dart';
import '../widgets/image_viewer_thumbnails.dart';

class ImageViewerPage extends HookConsumerWidget {
  const ImageViewerPage({required this.path, this.paths, super.key});
  final String path;
  final List<String>? paths;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = ref.watch(messageRepositoryProvider);
    final history = useFuture(
      useMemoized(() => repository.allImagePaths().run(), [repository]),
    );
    final images = useMemoized(
      () => List<String>.unmodifiable(<String>{
        ...?history.data?.getOrElse((_) => const <String>[]),
        ...?paths,
        path,
      }),
      [history.data, paths, path],
    );
    return GlassScaffold(
      backgroundColor: ImageViewerTokens.canvas,
      statusBarStyle: GlassStatusBarStyle.light,
      body: _ImageGallery(
        key: ValueKey(images),
        paths: images,
        initialPath: path,
      ),
    );
  }
}

class _ImageGallery extends HookConsumerWidget {
  const _ImageGallery({
    required this.paths,
    required this.initialPath,
    super.key,
  });
  final List<String> paths;
  final String initialPath;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final initial = paths.indexOf(initialPath);
    final selected = useState(initial);
    final controller = usePageController(initialPage: initial);
    final insets = MediaQuery.paddingOf(context);
    return Stack(
      children: [
        Positioned.fill(
          child: RepaintBoundary(
            child: PageView.builder(
              key: const ValueKey('image-viewer-pages'),
              controller: controller,
              itemCount: paths.length,
              onPageChanged: (slot) => selected.value = slot,
              itemBuilder: (_, slot) => ImageViewerImage(path: paths[slot]),
            ),
          ),
        ),
        if (paths.length > 1)
          Positioned(
            bottom: insets.bottom + AppSpacing.md,
            left: 0,
            right: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${selected.value + 1} / ${paths.length}',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: ImageViewerTokens.foreground,
                    shadows: const [ImageViewerTokens.controlShadow],
                  ),
                ),
                const Gap(AppSpacing.xs),
                ImageViewerThumbnails(
                  paths: paths,
                  selected: selected.value,
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
