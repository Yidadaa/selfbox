import 'package:flutter/material.dart';
import 'package:flutter_smooth_markdown/flutter_smooth_markdown.dart';

import 'app_glass_theme.dart';
import 'app_radius.dart';
import 'app_spacing.dart';

/// Markdown styling derived from the glass tokens, so AI replies and memory
/// files read as part of the same surface instead of a pasted document.
abstract final class AppMarkdownTheme {
  static MarkdownStyleSheet of(BuildContext context, {Color? textColor}) {
    final theme = Theme.of(context);
    final glass = context.glass;
    final color = textColor ?? glass.foreground;
    final base = theme.textTheme.bodyLarge?.copyWith(color: color, height: 1.5);
    final inset = BoxDecoration(
      color: glass.foreground.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(
        AppRadius.concentric(outer: AppRadius.md, padding: AppSpacing.xs),
      ),
    );
    return MarkdownStyleSheet.fromBrightness(
      theme.brightness,
      baseStyle: base,
    ).copyWith(
      codeBlockDecoration: inset,
      blockquoteDecoration: inset.copyWith(
        border: Border(left: BorderSide(color: glass.accent, width: 3)),
      ),
      linkStyle: base?.copyWith(color: glass.accent),
      blockSpacing: AppSpacing.sm,
    );
  }
}
