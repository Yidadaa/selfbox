import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:selfbox/core/theme/sdk_material.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_effects.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_icon.dart';
import '../../../../core/widgets/app_page_scaffold.dart';
import '../../../../core/widgets/pressable.dart';
import '../../../../gen/i18n/strings.g.dart';
import '../../../settings/presentation/providers/account_providers.dart';
import '../../../settings/presentation/widgets/profile_avatar.dart';
import '../widgets/chat_timeline_view.dart';
import '../widgets/chat_timestamp_session.dart';
import '../widgets/pinned_messages_overlay.dart';

class ChatPage extends ConsumerWidget {
  const ChatPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppPageScaffold(
      title: context.t.chat.title,
      titleContent: const _ChatHeaderProfile(),
      leading: const _ChatHeaderButton(),
      actions: const [_ChatSearchButton()],
      appBarHeight: AppSizes.chatHeaderHeight,
      // The shell already accounts for the keyboard in bottomInset.
      resizeToAvoidBottomInset: false,
      body: const Stack(
        fit: StackFit.expand,
        children: [
          ChatTimestampSession(child: ChatTimelineView()),
          PinnedMessagesOverlay(),
        ],
      ),
    );
  }
}

class _ChatHeaderProfile extends ConsumerWidget {
  const _ChatHeaderProfile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(
      userProfileProvider.select(
        (state) => (
          name: state.asData?.value.agentName.trim(),
          avatar: state.asData?.value.agentAvatar,
        ),
      ),
    );
    final name = profile.name;
    return Pressable(
      key: const ValueKey('chat-header-profile'),
      semanticLabel: context.t.me.editProfile,
      onTap: () => const ProfileRoute().push<void>(context),
      child: SizedBox(
        key: const ValueKey('chat-header-profile-layout'),
        width: 128,
        height: AppSizes.chatHeaderHeight,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: [
            Positioned(
              top: 60,
              child: GlassContainer(
                key: const ValueKey('chat-header-profile-surface'),
                quality: AppEffects.qualityOf(context, GlassQuality.premium),
                shape: const LiquidRoundedSuperellipse(
                  borderRadius: AppRadius.pill,
                ),
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.xs,
                  AppSpacing.md,
                  AppSpacing.xxs,
                ),
                child: Center(
                  child: Text(
                    name == null || name.isEmpty
                        ? context.t.me.agentDefaultName
                        : name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 10,
              child: ProfileAvatar(
                key: const ValueKey('chat-header-avatar'),
                path: profile.avatar,
                dimension: 56,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatHeaderButton extends StatelessWidget {
  const _ChatHeaderButton();

  @override
  Widget build(BuildContext context) => GlassIconButton(
    size: AppSizes.minTouchTarget,
    quality: AppEffects.qualityOf(context, GlassQuality.premium),
    icon: const AppIcon(AppIcons.settings),
    semanticLabel: context.t.chat.openSettings,
    onPressed: () => const MeRoute().go(context),
  );
}

class _ChatSearchButton extends StatelessWidget {
  const _ChatSearchButton();

  @override
  Widget build(BuildContext context) => GlassIconButton(
    size: AppSizes.minTouchTarget,
    quality: AppEffects.qualityOf(context, GlassQuality.premium),
    icon: const AppIcon(AppIcons.search),
    semanticLabel: context.t.chat.searchMessages,
    onPressed: () => const MessageSearchRoute().push<void>(context),
  );
}
