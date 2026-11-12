import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:path/path.dart' as p;

import '../../../../core/storage/app_paths.dart';
import '../../../../core/theme/app_glass_theme.dart';
import '../../../../core/theme/app_spacing.dart';

class ProfileAvatar extends ConsumerWidget {
  const ProfileAvatar({this.path, super.key});
  final String? path;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final relative = path;
    final valid = relative != null && p.posix.dirname(relative) == 'media';
    return ClipOval(
      child: ColoredBox(
        color: context.glass.surfaceTint,
        child: SizedBox.square(
          dimension: AppSizes.profileAvatar,
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
                  errorBuilder: (_, error, stack) => const _Placeholder(),
                )
              : const _Placeholder(),
        ),
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder();
  @override
  Widget build(BuildContext context) => Icon(
    Icons.person_outline_rounded,
    size: AppSizes.iconHero,
    color: context.glass.foregroundMuted,
  );
}
