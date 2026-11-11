import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../gen/i18n/strings.g.dart';
import '../../data/chat_data_providers.dart';

/// Full-screen, pinch-to-zoom view of one message image.
class ImageViewerPage extends ConsumerWidget {
  const ImageViewerPage({required this.path, super.key});

  final String path;

  static const _maxZoom = 5.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final file = ref.watch(mediaStoreProvider).resolve(path).toNullable();
    final insets = MediaQuery.paddingOf(context);
    return GlassScaffold(
      backgroundColor: Theme.of(context).colorScheme.scrim,
      body: Stack(
        children: [
          Positioned.fill(
            child: file == null
                ? EmptyState(
                    icon: Icons.broken_image_outlined,
                    label: context.t.chat.imageFailed,
                  )
                : InteractiveViewer(
                    maxScale: _maxZoom,
                    child: Center(
                      child: Image.file(
                        file,
                        errorBuilder: (_, _, _) => EmptyState(
                          icon: Icons.broken_image_outlined,
                          label: context.t.chat.imageFailed,
                        ),
                      ),
                    ),
                  ),
          ),
          Positioned(
            top: insets.top + AppSpacing.xs,
            left: AppSpacing.md,
            child: GlassIconButton(
              icon: const Icon(Icons.close_rounded),
              semanticLabel: context.t.common.close,
              size: AppSizes.minTouchTarget,
              onPressed: () => Navigator.of(context).maybePop(),
            ),
          ),
        ],
      ),
    );
  }
}
