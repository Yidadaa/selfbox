import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:selfbox/core/theme/sdk_material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/image_viewer_tokens.dart';
import '../../../../core/widgets/pressable.dart';
import '../../data/chat_data_providers.dart';

class ImageViewerThumbnail extends ConsumerWidget {
  const ImageViewerThumbnail({
    required this.path,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final String path;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final media = ref.watch(mediaStoreProvider);
    final thumbnail = media.thumbnail(path).toNullable();
    final file = thumbnail?.existsSync() == true
        ? thumbnail
        : media.resolve(path).toNullable();
    return Semantics(
      selected: selected,
      child: Pressable(
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(
              ImageViewerTokens.thumbnailRadius,
            ),
            boxShadow: selected
                ? const [ImageViewerTokens.selectionShadow]
                : null,
          ),
          child: DecoratedBox(
            key: selected
                ? const ValueKey('image-viewer-selected-thumbnail')
                : null,
            position: DecorationPosition.foreground,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(
                ImageViewerTokens.thumbnailRadius,
              ),
              border: selected
                  ? Border.all(
                      color: ImageViewerTokens.foreground,
                      width: ImageViewerTokens.thumbnailBorder,
                    )
                  : null,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(
                ImageViewerTokens.thumbnailRadius,
              ),
              child: ColoredBox(
                color: ImageViewerTokens.thumbnailFill,
                child: SizedBox.square(
                  dimension: AppSizes.attachmentThumbnail,
                  child: file == null
                      ? null
                      : Image.file(
                          file,
                          cacheWidth:
                              (AppSizes.attachmentThumbnail *
                                      MediaQuery.devicePixelRatioOf(context))
                                  .round(),
                          cacheHeight:
                              (AppSizes.attachmentThumbnail *
                                      MediaQuery.devicePixelRatioOf(context))
                                  .round(),
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => const SizedBox.shrink(),
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
