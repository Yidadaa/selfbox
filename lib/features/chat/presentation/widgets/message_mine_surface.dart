import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:selfbox/core/theme/sdk_material.dart';

import '../../../../core/theme/app_glass_theme.dart';
import '../../../../core/theme/message_tokens.dart';

class MessageMineSurface extends ConsumerWidget {
  const MessageMineSurface({required this.child, super.key});
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) => ClipPath(
    clipper: const _SpeechClipper(),
    child: ColoredBox(
      key: const ValueKey('message-surface'),
      color: context.glass.bubbleMine,
      child: child,
    ),
  );
}

class _SpeechClipper extends CustomClipper<Path> {
  const _SpeechClipper();

  @override
  Path getClip(Size size) {
    final width = size.width;
    final height = size.height;
    final radius = MessageTokens.radius.clamp(0.0, size.shortestSide / 2);
    const tail = MessageTokens.tail;
    return Path()
      ..moveTo(radius, 0)
      ..lineTo(width - radius - tail, 0)
      ..quadraticBezierTo(width - tail, 0, width - tail, radius)
      ..lineTo(width - tail, height - radius)
      ..quadraticBezierTo(width - tail, height - tail, width, height)
      ..quadraticBezierTo(width - tail, height, width - tail * 2, height - tail)
      ..quadraticBezierTo(width - radius, height, width - radius - tail, height)
      ..lineTo(radius, height)
      ..quadraticBezierTo(0, height, 0, height - radius)
      ..lineTo(0, radius)
      ..quadraticBezierTo(0, 0, radius, 0)
      ..close();
  }

  @override
  bool shouldReclip(_SpeechClipper oldClipper) => false;
}
