import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../core/theme/app_glass_theme.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/message_tokens.dart';
import '../../../../core/widgets/pressable.dart';
import '../../../../gen/i18n/strings.g.dart';

class MessageImageStack extends ConsumerWidget {
  const MessageImageStack({
    required this.paths,
    required this.resolveImage,
    this.onTap,
    super.key,
  });
  final List<String> paths;
  final File? Function(String) resolveImage;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context, WidgetRef ref) => Pressable(
    onTap: onTap,
    semanticLabel: context.t.chat.attachImage,
    child: SizedBox(
      width: MessageTokens.imageWidth,
      height:
          MessageTokens.imageHeight + (paths.length > 1 ? AppSpacing.md : 0),
      child: Stack(
        children: [
          for (var index = paths.take(3).length - 1; index >= 0; index--)
            Positioned(
              top: index * MessageTokens.stackInset,
              left: AppSpacing.xxs + index * MessageTokens.stackInset,
              right: AppSpacing.xxs + index * MessageTokens.stackInset,
              height: MessageTokens.imageHeight,
              child: Transform.rotate(
                angle: index.isEven ? 0 : MessageTokens.stackAngle,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    border: Border.all(color: context.glass.highlightBorder),
                    boxShadow: [
                      BoxShadow(
                        color: context.glass.shadowBorder,
                        blurRadius: AppSpacing.xs,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    child: _Photo(file: resolveImage(paths[index])),
                  ),
                ),
              ),
            ),
          if (paths.length > 1)
            Positioned(
              right: AppSpacing.sm,
              bottom: AppSpacing.xl,
              child: _PhotoCount(count: paths.length),
            ),
        ],
      ),
    ),
  );
}

class _PhotoCount extends StatelessWidget {
  const _PhotoCount({required this.count});
  final int count;
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: context.glass.bubbleOther,
      borderRadius: BorderRadius.circular(AppRadius.pill),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: AppSpacing.xxs,
      ),
      child: Text(
        '$count',
        style: Theme.of(context).textTheme.labelMedium
            ?.copyWith(color: context.glass.onBubbleOther),
      ),
    ),
  );
}

class _Photo extends ConsumerWidget {
  const _Photo({this.file});
  final File? file;
  @override
  Widget build(BuildContext context, WidgetRef ref) => switch (file) {
    final file? => Image.file(
      file,
      cacheWidth: kBubbleImageDecodeWidth,
      width: double.infinity,
      height: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => const _MissingPhoto(),
    ),
    null => const _MissingPhoto(),
  };
}

class _MissingPhoto extends ConsumerWidget {
  const _MissingPhoto();
  @override
  Widget build(BuildContext context, WidgetRef ref) => ColoredBox(
    color: context.glass.bubbleOther,
    child: Center(
      child: Icon(
        Icons.broken_image_outlined,
        color: context.glass.onBubbleOther,
      ),
    ),
  );
}
