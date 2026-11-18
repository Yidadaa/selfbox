import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:selfbox/core/theme/sdk_material.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_glass_theme.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_action_button.dart';
import '../../../../core/widgets/app_list_tile.dart';
import '../../../../core/widgets/app_modal_surface.dart';
import '../../../../gen/i18n/strings.g.dart';
import '../../../settings/presentation/providers/account_providers.dart';
import '../../domain/models/message.dart';
import '../providers/composer_controller.dart';
import '../providers/message_lookup.dart';

Future<void> showQuotedMessages(BuildContext context, List<int> ids) async {
  if (ids.isEmpty) return;
  final selected = ids.length == 1
      ? ids.single
      : await showAppBottomSheet<int>(
          context: context,
          isScrollControlled: true,
          useRootNavigator: true,
          builder: (_) => MessageQuoteSheet(ids: ids),
        );
  if (!context.mounted || selected == null) return;
  await MessageLocationRoute(id: selected).push<void>(context);
}

Future<void> showQuoteEditor(BuildContext context) => showAppBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useRootNavigator: true,
  builder: (_) => const MessageQuoteSheet(editable: true),
);

class MessageQuoteSheet extends ConsumerWidget {
  const MessageQuoteSheet({
    this.ids = const [],
    this.editable = false,
    super.key,
  });
  final List<int> ids;
  final bool editable;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (editable) {
      ref.listen(
        composerControllerProvider.select(
          (state) => state.quotedMessageIds.isEmpty,
        ),
        (previous, empty) {
          if (previous == false &&
              empty &&
              ModalRoute.of(context)?.isCurrent == true) {
            context.pop();
          }
        },
      );
    }
    final selected = editable
        ? ref.watch(
            composerControllerProvider.select(
              (state) => state.quotedMessageIds,
            ),
          )
        : ids;
    final sending =
        editable &&
        ref.watch(composerControllerProvider.select((state) => state.sending));
    final viewport = MediaQuery.sizeOf(context);
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    final safe = MediaQuery.paddingOf(context);
    final sheetHeight = (viewport.height * 0.5).clamp(
      0.0,
      (viewport.height - keyboard - safe.vertical).clamp(0.0, double.infinity),
    );
    return Padding(
      padding: EdgeInsets.only(bottom: keyboard),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: sheetHeight,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _QuoteSheetHeader(count: selected.length),
              const Gap(AppSpacing.xs),
              Expanded(
                child: selected.isEmpty
                    ? Center(
                        child: Text(
                          context.t.chat.noQuotes,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: context.glass.foregroundMuted),
                        ),
                      )
                    : ListView.builder(
                        itemCount: selected.length,
                        itemBuilder: (_, index) => _QuoteRow(
                          id: selected[index],
                          editable: editable,
                          sending: sending,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuoteRow extends ConsumerWidget {
  const _QuoteRow({
    required this.id,
    required this.editable,
    required this.sending,
  });
  final int id;
  final bool editable;
  final bool sending;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loaded = ref.watch(messageByIdProvider(id));
    final names = ref.watch(
      userProfileProvider.select(
        (value) => (
          user: value.value?.nickname.trim() ?? '',
          agent: value.value?.agentName.trim() ?? '',
        ),
      ),
    );
    final data = loaded.asData?.value;
    final message = data?.toNullable()?.toNullable();
    final failed = loaded.hasError || (data?.isLeft() ?? false);
    final label = message == null
        ? (failed ? context.t.common.loadFailed : context.t.chat.messageMissing)
        : message.text.trim().isEmpty
        ? context.t.chat.imageMessage(count: message.images.length)
        : message.text;
    return Skeletonizer(
      enabled: loaded.isLoading,
      child: AppListTile(
        key: ValueKey('quote-row-$id'),
        icon: AppIcons.quote,
        title: loaded.isLoading ? context.t.chat.fullMessage : label,
        subtitle: message == null
            ? null
            : switch (message.author) {
                MessageAuthor.me =>
                  names.user.isEmpty ? context.t.me.defaultName : names.user,
                MessageAuthor.ai =>
                  names.agent.isEmpty
                      ? context.t.me.agentDefaultName
                      : names.agent,
              },
        onTap: !editable && message != null ? () => context.pop(id) : null,
        trailing: editable
            ? AppActionIconButton(
                key: ValueKey('remove-quote-$id'),
                tooltip: context.t.common.delete,
                onPressed: sending
                    ? null
                    : () => ref
                          .read(composerControllerProvider.notifier)
                          .removeQuote(id),
                icon: AppIcons.delete,
              )
            : failed
            ? AppActionIconButton(
                onPressed: () => ref.invalidate(messageByIdProvider(id)),
                tooltip: context.t.common.retry,
                icon: AppIcons.refresh,
              )
            : null,
      ),
    );
  }
}

class _QuoteSheetHeader extends ConsumerWidget {
  const _QuoteSheetHeader({required this.count});
  final int count;
  @override
  Widget build(BuildContext context, WidgetRef ref) => Padding(
    padding: const EdgeInsets.fromLTRB(
      AppSpacing.md,
      AppSpacing.md,
      AppSpacing.md,
      0,
    ),
    child: Row(
      children: [
        Expanded(
          child: Text(
            context.t.chat.quotedCount(count: count),
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        AppActionIconButton(
          key: const ValueKey('message-quotes-close'),
          onPressed: () => context.pop(),
          tooltip: context.t.common.close,
          icon: AppIcons.close,
        ),
      ],
    ),
  );
}
