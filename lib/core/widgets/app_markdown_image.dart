import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_smooth_markdown/flutter_smooth_markdown.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../gen/i18n/strings.g.dart';
import '../theme/app_icons.dart';
import 'app_icon.dart';

class AppMarkdownImageBuilder extends MarkdownWidgetBuilder {
  const AppMarkdownImageBuilder();

  @override
  bool canBuild(MarkdownNode node) => node is ImageNode;

  @override
  Widget build(
    MarkdownNode node,
    MarkdownStyleSheet styleSheet,
    MarkdownRenderContext context,
  ) {
    final image = node as ImageNode;
    return _MarkdownImage(
      node: image,
      onTap: context.onTapImage == null
          ? null
          : () => context.onTapImage?.call(image.url, image.alt, image.title),
    );
  }
}

class _MarkdownImage extends StatelessWidget {
  const _MarkdownImage({required this.node, required this.onTap});
  final ImageNode node;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final uri = Uri.tryParse(node.url);
    final network = uri?.scheme == 'https' || uri?.scheme == 'http';
    final svg = uri?.path.toLowerCase().endsWith('.svg') ?? false;
    final failure = AppIcon(
      AppIcons.imageUnavailable,
      semanticLabel: context.t.chat.imageFailed,
    );
    final decodeWidth =
        (MediaQuery.sizeOf(context).width *
                MediaQuery.devicePixelRatioOf(context))
            .round();
    final image = switch ((network, svg)) {
      (true, true) => SvgPicture.network(
        node.url,
        errorBuilder: (_, _, _) => failure,
      ),
      (false, true) => SvgPicture.asset(
        node.url,
        errorBuilder: (_, _, _) => failure,
      ),
      (true, false) => CachedNetworkImage(
        imageUrl: node.url,
        memCacheWidth: decodeWidth,
        errorWidget: (_, _, _) => failure,
      ),
      (false, false) => Image.asset(
        node.url,
        cacheWidth: decodeWidth,
        errorBuilder: (_, _, _) => failure,
      ),
    };
    return Semantics(
      image: true,
      label: node.alt.isEmpty ? node.title : node.alt,
      child: GestureDetector(
        onTap: onTap,
        child: SizedBox(width: node.width, height: node.height, child: image),
      ),
    );
  }
}
