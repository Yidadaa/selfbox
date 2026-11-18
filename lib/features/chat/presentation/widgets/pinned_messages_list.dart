import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:selfbox/core/theme/sdk_material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/message_tokens.dart';
import '../../domain/models/message.dart';
import 'pinned_message_row.dart';

class PinnedMessagesList extends ConsumerWidget {
  const PinnedMessagesList({required this.messages, super.key});
  final List<Message> messages;

  @override
  Widget build(BuildContext context, WidgetRef ref) => ShaderMask(
    key: const ValueKey('pinned-message-edge-fade'),
    // Alpha reveals the actual solid/gradient surface in both themes.
    blendMode: BlendMode.dstIn,
    shaderCallback: (bounds) =>
        MessageTokens.pinnedListFade(bounds.height).createShader(bounds),
    child: RepaintBoundary(
      child: ListView.builder(
        key: const PageStorageKey('pinned-message-list'),
        primary: false,
        reverse: true,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          // Resting first/last messages stay outside the fading strips.
          vertical: MessageTokens.pinnedEdgeFadeExtent,
        ),
        itemCount: messages.length,
        itemBuilder: (_, index) => PinnedMessageRow(
          key: ValueKey(messages[index].id),
          message: messages[index],
        ),
      ),
    ),
  );
}
