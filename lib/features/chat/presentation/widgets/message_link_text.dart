import 'package:flutter/gestures.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:selfbox/core/theme/sdk_material.dart';

import '../../domain/services/message_links.dart';
import 'open_message_link.dart';

class MessageLinkText extends HookConsumerWidget {
  const MessageLinkText({
    required this.text,
    required this.style,
    required this.selectionMode,
    super.key,
  });
  final String text;
  final TextStyle? style;
  final bool selectionMode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final links = useMemoized(() => extractMessageLinks(text), [text]);
    final recognizers = useMemoized(
      () => [
        for (final link in links)
          TapGestureRecognizer()
            ..onTap = () => openMessageLink(context, ref, link.url),
      ],
      [links],
    );
    useEffect(
      () => () {
        for (final recognizer in recognizers) {
          recognizer.dispose();
        }
      },
      [recognizers],
    );
    if (links.isEmpty) return Text(text, style: style);
    return Text.rich(
      TextSpan(
        children: [
          for (var index = 0; index < links.length; index++) ...[
            TextSpan(
              style: style,
              text: text.substring(
                index == 0 ? 0 : links[index - 1].end,
                links[index].start,
              ),
            ),
            TextSpan(
              text: text.substring(links[index].start, links[index].end),
              style: style?.copyWith(
                decoration: TextDecoration.underline,
                decorationColor: style?.color,
              ),
              mouseCursor: SystemMouseCursors.click,
              recognizer: selectionMode ? null : recognizers[index],
            ),
          ],
          TextSpan(text: text.substring(links.last.end), style: style),
        ],
      ),
      style: style,
    );
  }
}
