import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../core/theme/app_glass_theme.dart';
import '../../../../core/theme/image_viewer_tokens.dart';
import '../../../../core/widgets/app_artwork.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../gen/i18n/strings.g.dart';
import '../../data/chat_data_providers.dart';

class ImageViewerImage extends HookConsumerWidget {
  const ImageViewerImage({required this.path, super.key});
  final String path;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final file = ref.watch(mediaStoreProvider).resolve(path).toNullable();
    final transform = useTransformationController();
    final zoomed = useListenableSelector(
      transform,
      () => transform.value.getMaxScaleOnAxis() > 1,
    );
    return file == null
        ? const _ImageUnavailable()
        : InteractiveViewer(
            transformationController: transform,
            panEnabled: zoomed,
            maxScale: ImageViewerTokens.maxZoom,
            child: Image.file(
              file,
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => const _ImageUnavailable(),
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
