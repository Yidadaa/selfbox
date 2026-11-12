import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../../core/error/failure_message.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_page_scaffold.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../gen/i18n/strings.g.dart';
import '../../../settings/presentation/widgets/settings_back_button.dart';
import '../../domain/models/message.dart';
import '../providers/message_search.dart';
import '../widgets/message_bubble.dart';

class MessageSearchPage extends HookConsumerWidget {
  const MessageSearchPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = useState('');
    final result = ref.watch(messageSearchProvider(query.value.trim()));
    return AppPageScaffold(
      title: context.t.chat.searchMessages,
      leading: const SettingsBackButton(),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              AppInsets.pageHorizontal,
              AppPageInsets.of(context).top,
              AppInsets.pageHorizontal,
              AppSpacing.sm,
            ),
            child: GlassTextField(
              key: const ValueKey('message-search-input'),
              autofocus: true,
              placeholder: context.t.chat.searchHint,
              surfaceStyle: GlassSurfaceStyle.solid,
              shape: const LiquidRoundedSuperellipse(
                borderRadius: AppRadius.sm,
              ),
              prefixIcon: const Icon(Icons.search_rounded),
              onChanged: (value) => query.value = value,
            ),
          ),
          Expanded(
            child: switch (result) {
              AsyncData(:final value) => value.match(
                (failure) => EmptyState(
                  label: failureMessage(context, failure),
                  action: GlassButton.custom(
                    onTap: () => ref.invalidate(
                      messageSearchProvider(query.value.trim()),
                    ),
                    height: AppSizes.minTouchTarget,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xl,
                      ),
                      child: Center(
                        widthFactor: 1,
                        child: Text(context.t.common.retry),
                      ),
                    ),
                  ),
                ),
                (messages) =>
                    _SearchResults(messages: messages, query: query.value),
              ),
              AsyncLoading() => const Center(
                child: Skeletonizer(child: _SearchResultSkeleton()),
              ),
              AsyncError() => EmptyState(
                label: context.t.settings.errors.generic,
                action: GlassButton.custom(
                  onTap: () =>
                      ref.invalidate(messageSearchProvider(query.value.trim())),
                  height: AppSizes.minTouchTarget,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xl,
                    ),
                    child: Center(
                      widthFactor: 1,
                      child: Text(context.t.common.retry),
                    ),
                  ),
                ),
              ),
            },
          ),
        ],
      ),
    );
  }
}

class _SearchResults extends StatelessWidget {
  const _SearchResults({required this.messages, required this.query});

  final List<Message> messages;
  final String query;

  @override
  Widget build(BuildContext context) {
    if (query.trim().isEmpty) {
      return EmptyState(label: context.t.chat.searchPrompt);
    }
    if (messages.isEmpty) {
      return EmptyState(label: context.t.chat.noSearchResults);
    }
    return ListView.separated(
      padding: EdgeInsets.fromLTRB(
        AppInsets.pageHorizontal,
        0,
        AppInsets.pageHorizontal,
        AppPageInsets.of(context).bottom,
      ),
      itemCount: messages.length,
      separatorBuilder: (_, _) => const Gap(AppSpacing.sm),
      itemBuilder: (context, index) =>
          MessageBubble(message: messages[index], resolveImage: (_) => null),
    );
  }
}

class _SearchResultSkeleton extends StatelessWidget {
  const _SearchResultSkeleton();

  @override
  Widget build(BuildContext context) => ListView(
    padding: EdgeInsets.fromLTRB(
      AppInsets.pageHorizontal,
      AppInsets.pageHorizontal,
      AppInsets.pageHorizontal,
      AppPageInsets.of(context).bottom,
    ),
    children: const [
      Text('A matching note'),
      Gap(AppSpacing.sm),
      Text('Another matching note'),
    ],
  );
}
