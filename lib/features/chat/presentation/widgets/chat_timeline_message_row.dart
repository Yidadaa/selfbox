import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_smooth_markdown/flutter_smooth_markdown.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../core/error/failure_message.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/widgets/app_action_popover.dart';
import '../../../../core/widgets/app_confirm_dialog.dart';
import '../../../../gen/i18n/strings.g.dart';
import '../../data/chat_data_providers.dart';
import '../../domain/models/message.dart';
import '../providers/composer_controller.dart';
import '../providers/message_actions.dart';
import 'chat_timestamp_session.dart';
import 'message_bubble.dart';
import 'message_quote_sheet.dart';
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
    final previewOverflow = useRef(false);
    final selection = useRef<SmoothSelectionController?>(null);
    final pressPosition = useRef(Offset.zero);
    void remove() {
      HapticFeedback.heavyImpact();
      selection.value?.clearSelection();
      selectionMode.value = false;
      final labels = context.t;
      showDialog<void>(
        context: context,
        builder: (_) => AppConfirmDialog(
          title: labels.chat.confirmDelete,
          secondaryLabel: labels.common.cancel,
          primaryLabel: labels.common.delete,
          destructive: true,
          onPrimary: () {
            if (context.mounted) {
              ref.read(messageActionsProvider.notifier).delete(message);
            }
          },
        ),
      );
    }

    final bubble = AppPopoverRegion(
      actions: [
        if (message.text.isNotEmpty)
          AppPopoverAction(
            label: context.t.common.copy,
            icon: AppIcons.copy,
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: message.text));
              if (context.mounted) {
                showOutcome(context, success: context.t.common.copied);
              }
            },
          ),
        if (message.text.isNotEmpty)
          AppPopoverAction(
            label: context.t.common.selectText,
            icon: AppIcons.selectText,
            onPressed: () {
              if (previewOverflow.value) {
                MessageExpandedRoute(id: message.id).push<void>(context);
                return;
              }
              selection.value ??= SmoothSelectionController();
              selectionMode.value = true;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (context.mounted) {
                    selection.value?.selectWordAt(pressPosition.value);
                  }
                });
              });
            },
          ),
        AppPopoverAction(
          label: context.t.chat.pin,
          icon: AppIcons.pin,
          onPressed: () async {
            unawaited(HapticFeedback.lightImpact());
            final result = await ref
                .read(messageActionsProvider.notifier)
                .pin(message.id, pinned: true);
            if (context.mounted) {
              result.match(
                (failure) => showOutcome(context, failure: failure),
                (_) {},
              );
            }
          },
        ),
        AppPopoverAction(
          label: context.t.common.quote,
          icon: AppIcons.quote,
          onPressed: () =>
              ref.read(composerControllerProvider.notifier).quote(message),
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
        onPreviewOverflow: (overflow) => previewOverflow.value = overflow,
        selectionController: selection.value,
        showTime:
            timestamps == null ||
            timestamps.showSeconds ||
            timestamps.timestampIds.contains(message.id),
        showSeconds: timestamps?.showSeconds ?? false,
        resolveImage: (path) => media.resolve(path).toNullable(),
        resolveThumbnail: (path) => media.thumbnail(path).toNullable(),
        onImageTap: (path) => ImageViewerRoute(
          path: path,
          $extra: message.images,
        ).push<void>(context),
        onExpand: () => MessageExpandedRoute(
          id: message.id,
          $extra: message,
        ).push<void>(context),
        onQuoteTap: () => showQuotedMessages(context, message.quotedMessageIds),
        onLongPress: selectionMode.value
            ? null
            : (position) {
                pressPosition.value = position;
                open(position);
              },
        onDelete: remove,
        onSelectionCopy: () {
          selectionMode.value = false;
          showOutcome(context, success: context.t.common.copied);
        },
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
