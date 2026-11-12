import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../gen/i18n/strings.g.dart';
import '../../data/chat_data_providers.dart';

/// Full-screen, pinch-to-zoom view of one message image.
class ImageViewerPage extends HookConsumerWidget {
  const ImageViewerPage({required this.path, this.paths, super.key});

  final String path;
  final List<String>? paths;

  static const _maxZoom = 5.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final images = switch (paths) {
      final items? when items.isNotEmpty => items,
      _ => [path],
    };
    final initial = images.indexOf(path).clamp(0, images.length - 1);
    final page = useState(initial);
    final controller = usePageController(initialPage: initial);
    final insets = MediaQuery.paddingOf(context);
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
              child: Center(
                child: GlassContainer(
                  quality: GlassQuality.standard,
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  child: Text(
                    '${page.value + 1} / ${images.length}',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ),
              ),
            ),
        ],
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
            icon: Icons.broken_image_outlined,
            label: context.t.chat.imageFailed,
          )
        : InteractiveViewer(
            maxScale: ImageViewerPage._maxZoom,
            child: Center(
              child: Image.file(
                file,
                errorBuilder: (_, _, _) => EmptyState(
                  icon: Icons.broken_image_outlined,
                  label: context.t.chat.imageFailed,
                ),
              ),
            ),
          );
  }
}
