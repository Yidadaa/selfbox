import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_smooth_markdown/flutter_smooth_markdown.dart';
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
import 'chat_timestamp_session.dart';
import 'message_bubble.dart';
import 'outgoing_message_entrance.dart';

class ChatTimelineMessageRow extends HookConsumerWidget {
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
    final timestamps = ChatTimestampScope.maybeOf(context);
    final selectionMode = useState(false);
    final selection = useMemoized(SmoothSelectionController.new);
    final pressPosition = useRef(Offset.zero);
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
        if (message.text.isNotEmpty)
          AppPopoverAction(
            label: context.t.common.selectText,
            icon: AppIcons.selectText,
            onPressed: () {
              selectionMode.value = true;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (context.mounted) {
                    selection.selectWordAt(pressPosition.value);
                  }
                });
              });
            },
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
        selectionMode: selectionMode.value,
        selectionController: selection,
        showTime:
            timestamps == null ||
            timestamps.showSeconds ||
            timestamps.timestampIds.contains(message.id),
        showSeconds: timestamps?.showSeconds ?? false,
        resolveImage: (path) => media.resolve(path).toNullable(),
        onImageTap: (path) => ImageViewerRoute(
          path: path,
          $extra: message.images,
        ).push<void>(context),
        onLongPress: selectionMode.value
            ? null
            : (position) {
                pressPosition.value = position;
                open(position);
              },
        onDelete: remove,
        onSelectionCopy: () => selectionMode.value = false,
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
