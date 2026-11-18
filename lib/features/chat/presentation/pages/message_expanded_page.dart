import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:selfbox/core/theme/sdk_material.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../../core/error/failure_message.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_effects.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_icon.dart';
import '../../../../core/widgets/app_page_button.dart';
import '../../../../core/widgets/app_page_scaffold.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../gen/i18n/strings.g.dart';
import '../../data/chat_data_providers.dart';
import '../../domain/models/message.dart';
import '../providers/message_lookup.dart';
import '../widgets/message_image_stack.dart';
import '../widgets/message_quote_link.dart';
import '../widgets/message_quote_sheet.dart';
import '../widgets/message_share_button.dart';
import '../widgets/message_text_content.dart';

class MessageExpandedPage extends ConsumerWidget {
  const MessageExpandedPage({required this.id, this.initial, super.key});
  final int id;
  final Message? initial;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loaded = ref.watch(messageByIdProvider(id));
    final message =
        loaded.asData?.value.toNullable()?.toNullable() ??
        (loaded.isLoading ? initial : null);
    return AppPageScaffold(
      title: context.t.chat.fullMessage,
      actions: [
        if (message != null && message.author == MessageAuthor.ai)
          MessageShareButton(message: message),
      ],
      leading: GlassIconButton(
        quality: AppEffects.qualityOf(context, GlassQuality.premium),
        size: AppSizes.minTouchTarget,
        icon: const AppIcon(AppIcons.close),
        semanticLabel: context.t.common.close,
        onPressed: () =>
            context.canPop() ? context.pop() : const ChatRoute().go(context),
      ),
      body: message != null
          ? _FullMessage(message: message)
          : loaded.isLoading
          ? const Skeletonizer(child: _LoadingMessage())
          : EmptyState(
              label: loaded.hasError || (loaded.asData?.value.isLeft() ?? false)
                  ? context.t.common.loadFailed
                  : context.t.chat.messageMissing,
              action: AppPageButton(
                onPressed: () => ref.invalidate(messageByIdProvider(id)),
                label: context.t.common.retry,
              ),
            ),
    );
  }
}

class _FullMessage extends ConsumerWidget {
  const _FullMessage({required this.message});
  final Message message;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final media = ref.watch(mediaStoreProvider);
    return ListView(
      key: ValueKey('full-message-${message.id}'),
      padding: AppPageInsets.of(context)
          .add(const EdgeInsets.all(AppSpacing.md)),
      children: [
        if (message.images.isNotEmpty)
          MessageImageStack(
            paths: message.images,
            resolveImage: (path) => media.resolve(path).toNullable(),
            onTap: () => ImageViewerRoute(
              path: message.images.first,
              $extra: message.images,
            ).push<void>(context),
          ),
        MessageTextContent(
          message: message,
          selectionMode: true,
          fullWidth: true,
          onSelectionCopy: () =>
              showOutcome(context, success: context.t.common.copied),
        ),
        if (message.quotedMessageIds.isNotEmpty)
          Align(
            alignment: Alignment.centerLeft,
            child: MessageQuoteLink(
              count: message.quotedMessageIds.length,
              onTap: () =>
                  showQuotedMessages(context, message.quotedMessageIds),
            ),
          ),
      ],
    );
  }
}

class _LoadingMessage extends StatelessWidget {
  const _LoadingMessage();
  @override
  Widget build(BuildContext context) => ListView(
    padding: AppPageInsets.of(context).add(const EdgeInsets.all(AppSpacing.md)),
    children: List.generate(6, (_) => Text(context.t.chat.fullMessage)),
  );
}
