import 'package:flutter/material.dart';
import 'package:flutter_smooth_markdown/flutter_smooth_markdown.dart';

import 'app_glass_theme.dart';
import 'app_radius.dart';
import 'app_spacing.dart';

/// Markdown styling derived from the glass tokens, so AI replies and memory
/// files read as part of the same surface instead of a pasted document.
abstract final class AppMarkdownTheme {
  static const double _headingSizeIncrement = 1;
  static const int thinkingVisibleLines = 3;
  static const double listMarkerGap = AppSpacing.xs;
  static const double taskMarkerSize = AppSpacing.lg;

  static MarkdownStyleSheet of(
    BuildContext context, {
    Color? textColor,
    bool thinking = false,
  }) {
    final theme = Theme.of(context);
    final glass = context.glass;
    final color = textColor ?? glass.foreground;
    final body = theme.textTheme.bodyLarge ?? const TextStyle(fontSize: 16);
    final base = body.copyWith(
      fontSize: thinking ? 14 : body.fontSize,
      color: thinking ? color.withValues(alpha: 0.72) : color,
      height: thinking ? 1.4 : 1.5,
    );
    final heading = base.copyWith(
      fontSize: (base.fontSize ?? 16) + (thinking ? 0 : _headingSizeIncrement),
      fontWeight: FontWeight.w600,
    );
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
      h1Style: heading,
      h2Style: heading,
      h3Style: heading,
      h4Style: heading,
      h5Style: heading,
      h6Style: heading,
      paragraphStyle: base,
      listBulletStyle: base,
      codeBlockDecoration: inset,
      blockquoteDecoration: inset.copyWith(
        border: Border(left: BorderSide(color: glass.accent, width: 3)),
      ),
      linkStyle: base.copyWith(color: glass.accent),
      blockSpacing: thinking ? AppSpacing.xxs : AppSpacing.sm,
    );
  }
}
