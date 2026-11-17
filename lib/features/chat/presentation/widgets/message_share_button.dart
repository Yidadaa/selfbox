import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../../../../core/error/app_failure.dart';
import '../../../../core/theme/app_effects.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_icon.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../gen/i18n/strings.g.dart';
import '../../domain/models/message.dart';
import '../providers/message_share.dart';
import '../services/message_share_renderer.dart';

class MessageShareButton extends ConsumerWidget {
  const MessageShareButton({required this.message, super.key});
  final Message message;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final busy = ref.watch(
      messageShareProvider(message.id).select((s) => s.isLoading),
    );
    return GlassIconButton(
      key: const ValueKey('share-message'),
      quality: AppEffects.qualityOf(context, GlassQuality.premium),
      size: AppSizes.minTouchTarget,
      icon: const AppIcon(AppIcons.share),
      semanticLabel: context.t.chat.shareMessage,
      onPressed: busy
          ? null
          : () async {
              final box = context.findRenderObject();
              if (box is! RenderBox || !box.hasSize) return;
              final result = await ref
                  .read(messageShareProvider(message.id).notifier)
                  .share(
                    image: ref.read(messageShareRendererProvider)(
                      context,
                      message,
                    ),
                    origin: box.localToGlobal(Offset.zero) & box.size,
                  );
              if (!context.mounted) return;
              result.match(
                (failure) => AppToast.show(
                  context,
                  type: GlassToastType.error,
                  message:
                      failure ==
                          const AppFailure.validation(
                            message: messageShareTooLong,
                          )
                      ? context.t.chat.shareTooLong
                      : context.t.chat.shareFailed,
                ),
                (_) {},
              );
            },
    );
  }
}
