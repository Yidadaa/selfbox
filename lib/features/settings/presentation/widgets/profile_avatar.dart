import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:path/path.dart' as p;

import '../../../../core/storage/app_paths.dart';
import '../../../../core/theme/app_glass_theme.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_artwork.dart';

class ProfileAvatar extends ConsumerWidget {
  const ProfileAvatar({
    this.path,
    this.dimension = AppSizes.profileAvatar,
    super.key,
  });
  final String? path;
  final double dimension;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final relative = path;
    final valid = relative != null && p.posix.dirname(relative) == 'media';
    return SizedBox.square(
      dimension: dimension,
      child: valid
          ? Image.file(
              File(
                p.join(
                  ref.watch(appPathsProvider).media.path,
                  p.posix.basename(relative),
                ),
              ),
              fit: BoxFit.cover,
              cacheWidth: 256,
              frameBuilder: (_, child, _, _) => ClipOval(child: child),
              errorBuilder: (_, error, stack) =>
                  _Placeholder(dimension: dimension),
            )
          : _Placeholder(dimension: dimension),
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.dimension});

  final double dimension;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    key: const ValueKey('default-avatar-surface'),
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: context.glass.bubbleOther,
    ),
    child: AppArtwork(BrandArt.avatar, size: dimension),
  );
}
