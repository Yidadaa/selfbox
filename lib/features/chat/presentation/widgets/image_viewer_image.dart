import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:selfbox/core/theme/sdk_material.dart';

import '../../../../core/theme/app_glass_theme.dart';
import '../../../../core/theme/image_viewer_tokens.dart';
import '../../../../core/widgets/app_artwork.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../gen/i18n/strings.g.dart';
import '../../data/chat_data_providers.dart';
import 'image_viewer_gestures.dart';

class ImageViewerImage extends HookConsumerWidget {
  const ImageViewerImage({required this.path, this.pager, super.key});
  final String path;
  final PageController? pager;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final file = ref.watch(mediaStoreProvider).resolve(path).toNullable();
    final zoom = useImageZoom(context);
    final paging = useImagePaging(context, pager, zoom.transform, zoom.stop);

    return file == null
        ? const _ImageUnavailable()
        : GestureDetector(
            onDoubleTapDown: zoom.onTapDown,
            onDoubleTap: zoom.onDoubleTap,
            child: InteractiveViewer(
              transformationController: zoom.transform,
              panEnabled: zoom.zoomed,
              maxScale: ImageViewerTokens.maxZoom,
              onInteractionStart: paging.start,
              onInteractionUpdate: paging.update,
              onInteractionEnd: paging.end,
              child: Image.file(
                file,
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => const _ImageUnavailable(),
              ),
            ),
          );
  }
}

class _ImageUnavailable extends ConsumerWidget {
  const _ImageUnavailable();
  @override
  Widget build(BuildContext context, WidgetRef ref) => EmptyState(
    illustration: BrandArt.error,
    label: context.t.chat.imageFailed,
    color: AppGlassTheme.dark.foregroundMuted,
  );
}
