import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../../../../core/theme/app_glass_theme.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_artwork.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../gen/i18n/strings.g.dart';
import '../../data/chat_data_providers.dart';

/// Full-screen, pinch-to-zoom view of all images referenced by the timeline.
class ImageViewerPage extends HookConsumerWidget {
  const ImageViewerPage({required this.path, this.paths, super.key});

  final String path;
  final List<String>? paths;

  static const _maxZoom = 5.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = ref.watch(messageRepositoryProvider);
    final history = useFuture(
      useMemoized(() => repository.allImagePaths().run(), [repository]),
    );
    final images = _mergePaths(
      history.data?.getOrElse((_) => const <String>[]) ?? const <String>[],
      paths ?? const <String>[],
      path,
    );
    final initial = images.indexOf(path).clamp(0, images.length - 1);
    final page = useState(initial);
    final controller = usePageController(initialPage: initial);
    final insets = MediaQuery.paddingOf(context);

    useEffect(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!controller.hasClients || controller.page?.round() == initial) {
          return;
        }
        controller.jumpToPage(initial);
        page.value = initial;
      });
      return null;
    }, [images.length, initial]);

    return GlassScaffold(
      backgroundColor: Theme.of(context).colorScheme.scrim,
      body: Stack(
        children: [
          Positioned.fill(
            child: PageView.builder(
              controller: controller,
              itemCount: images.length,
              onPageChanged: (value) => page.value = value,
              itemBuilder: (context, index) =>
                  _ViewerImage(path: images[index]),
            ),
          ),
          Positioned(
            top: insets.top + AppSpacing.xs,
            left: AppInsets.pageHorizontal,
            child: GlassIconButton(
              key: const ValueKey('image-viewer-close'),
              quality: GlassQuality.premium,
              icon: const Icon(Icons.close_rounded),
              semanticLabel: context.t.common.close,
              size: AppSizes.minTouchTarget,
              onPressed: () => context.pop(),
            ),
          ),
          if (images.length > 1)
            Positioned(
              bottom: insets.bottom + AppSpacing.md,
              left: AppInsets.pageHorizontal,
              right: AppInsets.pageHorizontal,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${page.value + 1} / ${images.length}',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const Gap(AppSpacing.xs),
                  _ThumbnailStrip(
                    paths: images,
                    selected: page.value,
                    onSelected: (index) {
                      page.value = index;
                      controller.animateToPage(
                        index,
                        duration: const Duration(milliseconds: 240),
                        curve: Curves.easeOutCubic,
                      );
                    },
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

List<String> _mergePaths(
  List<String> history,
  List<String> routePaths,
  String current,
) => List.unmodifiable(<String>{...history, ...routePaths, current});

class _ThumbnailStrip extends HookConsumerWidget {
  const _ThumbnailStrip({
    required this.paths,
    required this.selected,
    required this.onSelected,
  });

  final List<String> paths;
  final int selected;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final media = ref.watch(mediaStoreProvider);
    final controller = useScrollController();
    useEffect(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!controller.hasClients) return;
        final position = controller.position;
        final target =
            (selected * (AppSizes.attachmentThumbnail + AppSpacing.xs) -
                    (position.viewportDimension -
                            AppSizes.attachmentThumbnail) /
                        2)
                .clamp(0.0, position.maxScrollExtent);
        controller.animateTo(
          target,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
        );
      });
      return null;
    }, [controller, selected, paths.length]);
    return GlassContainer(
      quality: GlassQuality.standard,
      padding: const EdgeInsets.all(AppSpacing.xs),
      child: ConstrainedBox(
        constraints: const BoxConstraints.tightFor(
          height: AppSizes.attachmentThumbnail,
        ),
        child: ListView.builder(
          key: const ValueKey('image-viewer-thumbnails'),
          controller: controller,
          scrollDirection: Axis.horizontal,
          itemCount: paths.length,
          itemBuilder: (context, index) {
            final path = paths[index];
            return Padding(
              padding: const EdgeInsetsDirectional.only(end: AppSpacing.xs),
              child: _ImageThumbnail(
                key: ValueKey('image-thumbnail-$path'),
                selected: index == selected,
                thumbnail: media.thumbnail(path).toNullable(),
                original: media.resolve(path).toNullable(),
                onTap: () => onSelected(index),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ImageThumbnail extends StatelessWidget {
  const _ImageThumbnail({
    required this.selected,
    required this.thumbnail,
    required this.original,
    required this.onTap,
    super.key,
  });

  final bool selected;
  final File? thumbnail;
  final File? original;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final file = thumbnail?.existsSync() == true ? thumbnail : original;
    return GestureDetector(
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: selected
              ? Border.all(
                  color: Theme.of(context).colorScheme.primary,
                  width: 2,
                )
              : null,
          borderRadius: BorderRadius.circular(AppSpacing.xs),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.xs),
          child: file == null
              ? const SizedBox(
                  width: AppSizes.attachmentThumbnail,
                  height: AppSizes.attachmentThumbnail,
                )
              : Image.file(
                  file,
                  width: AppSizes.attachmentThumbnail,
                  height: AppSizes.attachmentThumbnail,
                  cacheWidth: (AppSizes.attachmentThumbnail * 2).round(),
                  cacheHeight: (AppSizes.attachmentThumbnail * 2).round(),
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const SizedBox(
                    width: AppSizes.attachmentThumbnail,
                    height: AppSizes.attachmentThumbnail,
                  ),
                ),
        ),
      ),
    );
  }
}

class _ViewerImage extends ConsumerWidget {
  const _ViewerImage({required this.path});
  final String path;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final file = ref.watch(mediaStoreProvider).resolve(path).toNullable();
    return file == null
        ? EmptyState(
            illustration: BrandArt.error,
            label: context.t.chat.imageFailed,
            color: AppGlassTheme.dark.foregroundMuted,
          )
        : InteractiveViewer(
            maxScale: ImageViewerPage._maxZoom,
            child: Center(
              child: Image.file(
                file,
                errorBuilder: (_, _, _) => EmptyState(
                  illustration: BrandArt.error,
                  label: context.t.chat.imageFailed,
                  color: AppGlassTheme.dark.foregroundMuted,
                ),
              ),
            ),
          );
  }
}
