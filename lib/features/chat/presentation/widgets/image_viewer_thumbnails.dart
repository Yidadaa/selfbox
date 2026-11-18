import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:selfbox/core/theme/sdk_material.dart';

import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/image_viewer_tokens.dart';
import 'image_viewer_thumbnail.dart';

class ImageViewerThumbnails extends ConsumerWidget {
  const ImageViewerThumbnails({
    required this.paths,
    required this.selected,
    required this.onSelected,
    required this.onScrub,
    super.key,
  });
  final List<String> paths;
  final int selected;
  final ValueChanged<int> onSelected;
  final ValueChanged<int> onScrub;

  @override
  Widget build(BuildContext context, WidgetRef ref) => SizedBox(
    height: AppSizes.attachmentThumbnail,
    child: LayoutBuilder(
      builder: (_, constraints) => _ThumbnailCarousel(
        key: ValueKey(constraints.maxWidth),
        width: constraints.maxWidth,
        paths: paths,
        selected: selected,
        onSelected: onSelected,
        onScrub: onScrub,
      ),
    ),
  );
}

class _ThumbnailCarousel extends HookConsumerWidget {
  const _ThumbnailCarousel({
    required this.width,
    required this.paths,
    required this.selected,
    required this.onSelected,
    required this.onScrub,
    super.key,
  });
  final double width;
  final List<String> paths;
  final int selected;
  final ValueChanged<int> onSelected;
  final ValueChanged<int> onScrub;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = usePageController(
      initialPage: selected,
      viewportFraction: ImageViewerTokens.thumbnailExtent / width,
    );
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    useEffect(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted ||
            !controller.hasClients ||
            controller.page?.round() == selected) {
          return;
        }
        if (reduceMotion) {
          controller.jumpToPage(selected);
        } else {
          controller.animateToPage(
            selected,
            duration: AppMotion.medium,
            curve: AppMotion.emphasized,
          );
        }
      });
      return null;
    }, [selected, reduceMotion]);
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification.depth != 0 || !controller.hasClients) return false;
        if (notification is ScrollUpdateNotification &&
            notification.dragDetails == null) {
          return false;
        }
        if (notification is! ScrollUpdateNotification &&
            notification is! ScrollEndNotification) {
          return false;
        }
        final index = controller.page?.round();
        if (index != null && index != selected) onScrub(index);
        return false;
      },
      child: PageView.builder(
        key: const ValueKey('image-viewer-thumbnails'),
        controller: controller,
        itemCount: paths.length,
        itemBuilder: (_, slot) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxs),
          child: ImageViewerThumbnail(
            key: ValueKey(slot),
            path: paths[slot],
            selected: slot == selected,
            onTap: () => onSelected(slot),
          ),
        ),
      ),
    );
  }
}
