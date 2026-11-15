import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../core/theme/message_tokens.dart';
import '../../../../core/widgets/pressable.dart';
import '../../../../gen/i18n/strings.g.dart';

class MessageQuoteLink extends ConsumerWidget {
  const MessageQuoteLink({required this.count, required this.onTap, super.key});
  final int count;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Pressable(
    key: const ValueKey('message-quote-link'),
    minSize: 0,
    onTap: onTap,
    child: Text(
      context.t.chat.quotedCount(count: count),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: MessageTokens.quoteColor(Theme.of(context).brightness),
      ),
    ),
  );
}
