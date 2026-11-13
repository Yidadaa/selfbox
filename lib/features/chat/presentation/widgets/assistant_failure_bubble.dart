import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../core/error/app_failure.dart';
import '../../../../core/error/failure_message.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_glass_theme.dart';
import '../../../../core/theme/app_markdown_theme.dart';
import '../../../../core/theme/message_tokens.dart';
import '../../../../gen/i18n/strings.g.dart';
import '../providers/assistant_controller.dart';
import 'assistant_live_bubbles.dart';

class AssistantFailureBubble extends ConsumerWidget {
  const AssistantFailureBubble({required this.failure, super.key});

  final AppFailure failure;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t;
    final controller = ref.read(assistantControllerProvider.notifier);
    final needsSetup = switch (failure) {
      ValidationFailure(message: AppFailure.noModel) ||
      ValidationFailure(message: AppFailure.missingApiKey) => true,
      ValidationFailure() ||
      NetworkFailure() ||
      DatabaseFailure() ||
      PermissionFailure() ||
      UnexpectedFailure() => false,
    };
    final style = AppMarkdownTheme.of(
      context,
      textColor: context.glass.onBubbleOther,
    ).paragraphStyle;
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.sizeOf(context).width * MessageTokens.widthFactor,
      ),
      child: AssistantStatusSurface(
        child: Material(
          type: MaterialType.transparency,
          child: Text.rich(
            key: const ValueKey('assistant-failure-text'),
            style: style,
            // A wrapped line containing only a button keeps normal text metrics.
            strutStyle: StrutStyle.fromTextStyle(
              style ?? const TextStyle(),
              forceStrutHeight: true,
            ),
            TextSpan(
              text: failureMessage(context, failure),
              children: [
                const TextSpan(text: ' '),
                WidgetSpan(
                  alignment: PlaceholderAlignment.baseline,
                  baseline: TextBaseline.alphabetic,
                  child: _InlineAction(
                    key: const ValueKey('assistant-failure-action'),
                    label: needsSetup ? t.assistant.setup : t.common.retry,
                    style: style,
                    onPressed: needsSetup
                        ? () {
                            controller.dismiss();
                            const AiProvidersRoute().go(context);
                          }
                        : controller.retry,
                  ),
                ),
                const TextSpan(text: ' '),
                WidgetSpan(
                  alignment: PlaceholderAlignment.baseline,
                  baseline: TextBaseline.alphabetic,
                  child: _InlineAction(
                    key: const ValueKey('assistant-failure-dismiss'),
                    label: t.assistant.dismiss,
                    style: style,
                    onPressed: controller.dismiss,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InlineAction extends StatelessWidget {
  const _InlineAction({
    required this.label,
    required this.style,
    required this.onPressed,
    super.key,
  });

  final String label;
  final TextStyle? style;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => TextButton(
    onPressed: () {
      HapticFeedback.lightImpact();
      onPressed();
    },
    // Inline actions inherit paragraph height instead of a standalone hit box.
    style: TextButton.styleFrom(
      minimumSize: Size.zero,
      padding: EdgeInsets.zero,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.standard,
      textStyle: style,
      foregroundColor: context.glass.accent,
    ),
    // WidgetSpan already applies the paragraph's text scaling.
    child: Text(
      label,
      style: style?.copyWith(color: context.glass.accent),
      textScaler: TextScaler.noScaling,
    ),
  );
}
