import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_smooth_markdown/flutter_smooth_markdown.dart';
import 'package:gap/gap.dart';

import '../../../../core/theme/app_glass_theme.dart';
import '../../../../core/theme/app_markdown_theme.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/message_tokens.dart';
import '../../../../core/widgets/app_markdown_builders.dart';

class AssistantStatusSurface extends StatelessWidget {
  const AssistantStatusSurface({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    const round = Radius.circular(AppRadius.md);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.glass.bubbleOther,
        borderRadius: const BorderRadius.only(
          topLeft: round,
          topRight: round,
          bottomRight: round,
          bottomLeft: Radius.circular(AppRadius.xs),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: child,
      ),
    );
  }
}

class AssistantThinkingBubble extends HookWidget {
  const AssistantThinkingBubble({
    required this.text,
    required this.fallback,
    super.key,
  });

  final String text;
  final String fallback;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final stream = useMemoized(StreamController<String>.new);
    final previous = useRef('');
    final scroll = useScrollController();
    useEffect(() {
      return () => unawaited(stream.close());
    }, [stream]);
    useEffect(() {
      if (text.startsWith(previous.value)) {
        final delta = text.substring(previous.value.length);
        if (delta.isNotEmpty) stream.add(delta);
      }
      previous.value = text;
      return null;
    }, [text]);

    final sheet = AppMarkdownTheme.of(
      context,
      textColor: glass.onBubbleOther,
      thinking: true,
    );
    final fontSize = sheet.paragraphStyle?.fontSize ?? 16;
    final lineHeight = sheet.paragraphStyle?.height ?? 1.5;
    final maxHeight =
        MediaQuery.textScalerOf(context).scale(fontSize) *
        lineHeight *
        AppMarkdownTheme.thinkingVisibleLines;
    return Semantics(
      label: text.isEmpty ? fallback : '$fallback $text',
      child: ExcludeSemantics(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth:
                MediaQuery.sizeOf(context).width * MessageTokens.widthFactor,
          ),
          child: AssistantStatusSurface(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.auto_awesome_rounded,
                  size: AppSpacing.md,
                  color: glass.accent,
                ),
                const Gap(AppSpacing.xs),
                Flexible(
                  child: text.isEmpty
                      ? Text(
                          fallback,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: glass.foregroundMuted),
                        )
                      : _ReasoningViewport(
                          stream: stream.stream,
                          scroll: scroll,
                          sheet: sheet,
                          maxHeight: maxHeight,
                        ),
                ),
                const Gap(AppSpacing.xxs),
                AssistantPendingIndicator(color: glass.accent),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ReasoningViewport extends StatelessWidget {
  const _ReasoningViewport({
    required this.stream,
    required this.scroll,
    required this.sheet,
    required this.maxHeight,
  });

  final Stream<String> stream;
  final ScrollController scroll;
  final MarkdownStyleSheet sheet;
  final double maxHeight;

  @override
  Widget build(BuildContext context) {
    void followLatest() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!scroll.hasClients) return;
        unawaited(
          scroll.animateTo(
            scroll.position.maxScrollExtent,
            duration: AppMotion.fast,
            curve: AppMotion.emphasized,
          ),
        );
      });
    }

    return ConstrainedBox(
      key: const ValueKey('thinking-viewport'),
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: ShaderMask(
        key: const ValueKey('thinking-fade'),
        blendMode: BlendMode.dstIn,
        shaderCallback: (bounds) {
          final edge = (AppSpacing.xs / bounds.height).clamp(0.0, 0.4);
          return LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: const [
              Colors.transparent,
              Colors.black,
              Colors.black,
              Colors.transparent,
            ],
            stops: [0, edge, 1 - edge, 1],
          ).createShader(bounds);
        },
        child: NotificationListener<SizeChangedLayoutNotification>(
          onNotification: (_) {
            followLatest();
            return false;
          },
          child: SingleChildScrollView(
            key: const ValueKey('thinking-scroll'),
            controller: scroll,
            physics: const NeverScrollableScrollPhysics(),
            child: SizeChangedLayoutNotifier(
              child: StreamMarkdown(
                stream: stream,
                styleSheet: sheet,
                builderRegistry: appMarkdownBuilders(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AssistantTypingBubble extends HookWidget {
  const AssistantTypingBubble({required this.label, super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    return Semantics(
      label: label,
      child: ExcludeSemantics(
        child: AssistantStatusSurface(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(color: glass.onBubbleOther),
              ),
              const Gap(AppSpacing.xs),
              AssistantPendingIndicator(
                color: glass.accent,
                keyPrefix: 'typing-dot',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AssistantPendingIndicator extends HookWidget {
  const AssistantPendingIndicator({
    required this.color,
    this.keyPrefix = 'pending-dot',
    super.key,
  });

  final Color color;
  final String keyPrefix;

  @override
  Widget build(BuildContext context) {
    final animation = useAnimationController(duration: AppMotion.slow * 3);
    useEffect(() {
      animation.repeat();
      return null;
    }, [animation]);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var index = 0; index < 3; index++) ...[
          if (index > 0) const Gap(AppSpacing.xxs),
          AnimatedBuilder(
            animation: animation,
            builder: (context, child) {
              final phase = (animation.value * 3 - index) % 3;
              final lift = phase < 1
                  ? math.sin(math.pi * phase) * AppSpacing.xxs
                  : 0.0;
              return Transform.translate(
                key: ValueKey('$keyPrefix-$index'),
                offset: Offset(0, -lift),
                child: child,
              );
            },
            child: DecoratedBox(
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              child: const SizedBox.square(dimension: AppSpacing.xxs),
            ),
          ),
        ],
      ],
    );
  }
}
