import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/router/shell_scope.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_page_scaffold.dart';
import '../../../../core/widgets/pressable.dart';
import '../../../../gen/i18n/strings.g.dart';
import '../../../settings/presentation/providers/account_providers.dart';
import '../../../settings/presentation/widgets/profile_avatar.dart';
import '../widgets/chat_timeline_view.dart';

class ChatPage extends ConsumerWidget {
  const ChatPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listBottom = ShellScope.bottomInsetOf(context) + AppSpacing.sm;

    return AppPageScaffold(
      title: context.t.chat.title,
      titleContent: const _ChatHeaderProfile(),
      leading: const _ChatHeaderButton(),
      actions: const [_ChatSearchButton()],
      appBarHeight: AppSizes.chatHeaderHeight,
      // The shell already accounts for the keyboard in bottomInset.
      resizeToAvoidBottomInset: false,
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusScope.of(context).unfocus(),
        child: ChatTimelineView(bottomPadding: listBottom),
      ),
    );
  }
}

class _ChatHeaderProfile extends ConsumerWidget {
  const _ChatHeaderProfile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = switch (ref.watch(userProfileProvider)) {
      AsyncData(:final value) => value,
      AsyncLoading() || AsyncError() => null,
    };
    final name = profile?.nickname.trim();
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
                quality: GlassQuality.standard,
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
                        ? context.t.me.defaultName
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
                path: profile?.avatar,
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
    quality: GlassQuality.premium,
    icon: const Icon(Icons.settings_outlined),
    semanticLabel: context.t.chat.openSettings,
    onPressed: () => const MeRoute().go(context),
  );
}

class _ChatSearchButton extends StatelessWidget {
  const _ChatSearchButton();

  @override
  Widget build(BuildContext context) => GlassIconButton(
    quality: GlassQuality.premium,
    icon: const Icon(Icons.search_rounded),
    semanticLabel: context.t.chat.searchMessages,
    onPressed: () => const MessageSearchRoute().push<void>(context),
  );
}
