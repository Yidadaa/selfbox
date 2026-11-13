import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/message_tokens.dart';
import '../../../../core/widgets/app_action_popover.dart';
import '../../../../gen/i18n/strings.g.dart';
import '../../data/chat_data_providers.dart';
import '../../domain/models/message.dart';
import '../providers/message_actions.dart';
import 'message_bubble.dart';
import 'outgoing_message_entrance.dart';

class ChatTimelineMessageRow extends ConsumerWidget {
  const ChatTimelineMessageRow({
    required this.message,
    required this.entering,
    required this.onEntered,
    super.key,
  });

  final Message message;
  final bool entering;
  final VoidCallback onEntered;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final media = ref.watch(mediaStoreProvider);
    void remove() {
      HapticFeedback.heavyImpact();
      ref.read(messageActionsProvider.notifier).delete(message);
    }

    final bubble = AppPopoverRegion(
      radius: message.text.isEmpty
          ? MessageTokens.imageFrameRadius
          : MessageTokens.radius,
      actions: [
        if (message.text.isNotEmpty)
          AppPopoverAction(
            label: context.t.common.copy,
            icon: AppIcons.copy,
            onPressed: () =>
                Clipboard.setData(ClipboardData(text: message.text)),
          ),
        AppPopoverAction(
          label: context.t.common.delete,
          icon: AppIcons.delete,
          destructive: true,
          onPressed: remove,
        ),
      ],
      builder: (_, open) => MessageBubble(
        message: message,
        resolveImage: (path) => media.resolve(path).toNullable(),
        onImageTap: (path) => ImageViewerRoute(
          path: path,
          $extra: message.images,
        ).push<void>(context),
        onLongPress: open,
        onDelete: remove,
      ),
    );
    return entering
        ? OutgoingMessageEntrance(
            onComplete: onEntered,
            // AI stages share a left anchor; only a user send travels from
            // the composer on the right.
            alignment: message.author == MessageAuthor.ai
                ? Alignment.bottomLeft
                : Alignment.bottomRight,
            offset: message.author == MessageAuthor.ai
                ? AppMotion.assistantStageOffset
                : AppMotion.messageSendOffset,
            child: bubble,
          )
        : bubble;
  }
}
