import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../../../../core/theme/image_viewer_tokens.dart';
import '../../data/chat_data_providers.dart';
import '../widgets/image_viewer_chrome.dart';
import '../widgets/image_viewer_image.dart';

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
    return Stack(
      children: [
        Positioned.fill(
          child: RepaintBoundary(
            child: PageView.builder(
              key: const ValueKey('image-viewer-pages'),
              controller: controller,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: paths.length,
              onPageChanged: (slot) => selected.value = slot,
              itemBuilder: (_, slot) => ImageViewerImage(
                key: ValueKey(paths[slot]),
                path: paths[slot],
                pager: controller,
              ),
            ),
          ),
        ),
        ImageViewerChrome(
          paths: paths,
          selected: selected.value,
          controller: controller,
        ),
      ],
    );
  }
}
