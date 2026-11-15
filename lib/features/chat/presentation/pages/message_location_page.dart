import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_effects.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_icon.dart';
import '../../../../core/widgets/app_page_button.dart';
import '../../../../core/widgets/app_page_scaffold.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../gen/i18n/strings.g.dart';
import '../../domain/models/message.dart';
import '../providers/message_lookup.dart';
import '../widgets/chat_timeline_message_row.dart';

class MessageLocationPage extends ConsumerWidget {
  const MessageLocationPage({required this.id, super.key});
  final int id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loaded = ref.watch(messageByIdProvider(id));
    final message = loaded.asData?.value.toNullable()?.toNullable();
    return AppPageScaffold(
      title: context.t.chat.fullMessage,
      leading: GlassIconButton(
        quality: AppEffects.qualityOf(context, GlassQuality.premium),
        size: AppSizes.minTouchTarget,
        icon: const AppIcon(AppIcons.back),
        semanticLabel: context.t.common.close,
        onPressed: () =>
            context.canPop() ? context.pop() : const ChatRoute().go(context),
      ),
      body: message != null
          ? _LocatedMessage(message: message)
          : loaded.isLoading
          ? Skeletonizer(child: Center(child: Text(context.t.chat.fullMessage)))
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

class _LocatedMessage extends ConsumerWidget {
  const _LocatedMessage({required this.message});
  final Message message;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      key: ValueKey('message-location-${message.id}'),
      padding: AppPageInsets.of(context),
      children: [
        ChatTimelineMessageRow(
          key: ValueKey('located-${message.id}'),
          message: message,
          entering: false,
          onEntered: () {},
        ),
      ],
    );
  }
}
