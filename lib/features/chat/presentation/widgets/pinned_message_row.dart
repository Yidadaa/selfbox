import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../core/error/failure_message.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/widgets/app_action_popover.dart';
import '../../../../gen/i18n/strings.g.dart';
import '../../data/chat_data_providers.dart';
import '../../domain/models/message.dart';
import '../providers/message_actions.dart';
import 'message_bubble.dart';
import 'message_quote_sheet.dart';

class PinnedMessageRow extends ConsumerWidget {
  const PinnedMessageRow({required this.message, super.key});
  final Message message;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final media = ref.watch(mediaStoreProvider);
    return AppPopoverRegion(
      actions: [
        AppPopoverAction(
          label: context.t.chat.unpin,
          icon: AppIcons.delete,
          onPressed: () async {
            final result = await ref
                .read(messageActionsProvider.notifier)
                .pin(message.id, pinned: false);
            if (context.mounted) {
              result.match(
                (failure) => showOutcome(context, failure: failure),
                (_) {},
              );
            }
          },
        ),
      ],
      builder: (_, open) => MessageBubble(
        message: message,
        preview: false,
        resolveImage: (path) => media.resolve(path).toNullable(),
        resolveThumbnail: (path) => media.thumbnail(path).toNullable(),
        onLongPress: open,
        onImageTap: (path) => ImageViewerRoute(
          path: path,
          $extra: message.images,
        ).push<void>(context),
        onQuoteTap: () => showQuotedMessages(context, message.quotedMessageIds),
      ),
    );
  }
}
