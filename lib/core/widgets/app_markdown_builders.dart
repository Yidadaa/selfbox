import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_smooth_markdown/flutter_smooth_markdown.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../theme/app_icons.dart';
import '../theme/app_markdown_theme.dart';
import '../theme/app_spacing.dart';
import 'app_icon.dart';
import 'app_markdown_image.dart';

BuilderRegistry appMarkdownBuilders() => BuilderRegistry()
  ..register('blockquote', const _QuoteBuilder())
  ..register('list', const _ListBuilder())
  ..register('image', const AppMarkdownImageBuilder());

class _QuoteBuilder extends MarkdownWidgetBuilder {
  const _QuoteBuilder();

  @override
  bool canBuild(MarkdownNode node) => node is BlockquoteNode;

  @override
  Widget build(
    MarkdownNode node,
    MarkdownStyleSheet styleSheet,
    MarkdownRenderContext context,
  ) {
    final quote = node as BlockquoteNode;
    final content = context.blockRenderer?.call(quote.children);
    return Container(
      decoration: styleSheet.blockquoteDecoration ?? const BoxDecoration(),
      padding: styleSheet.blockquotePadding,
      child: content ?? const SizedBox.shrink(),
    );
  }
}

class _ListBuilder extends MarkdownWidgetBuilder {
  const _ListBuilder();

  @override
  bool canBuild(MarkdownNode node) => node is ListNode;

  @override
  Widget build(
    MarkdownNode node,
    MarkdownStyleSheet styleSheet,
    MarkdownRenderContext context,
  ) => _MarkdownList(
    node: node as ListNode,
    sheet: styleSheet,
    renderContext: context,
  );
}

class _MarkdownList extends HookConsumerWidget {
  const _MarkdownList({
    required this.node,
    required this.sheet,
    required this.renderContext,
  });

  final ListNode node;
  final MarkdownStyleSheet sheet;
  final MarkdownRenderContext renderContext;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final style = DefaultTextStyle.of(context).style
        .merge(sheet.listBulletStyle);
    final labels = [
      for (var i = 0; i < node.items.length; i++)
        node.ordered ? '${node.startIndex + i}.' : '•',
    ];
    final direction = Directionality.of(context);
    final scaler = MediaQuery.textScalerOf(context);
    final locale = Localizations.maybeLocaleOf(context);
    final markerWidth = useMemoized(() {
      final painter = TextPainter(
        textDirection: direction,
        textScaler: scaler,
        locale: locale,
      );
      var width = node.items.any((item) => item.checked != null)
          ? AppMarkdownTheme.taskMarkerSize
          : 0.0;
      final markers = {
        for (final (index, item) in node.items.indexed)
          if (item.checked == null) labels[index],
      };
      for (final marker in markers) {
        painter.text = TextSpan(text: marker, style: style);
        painter.layout();
        width = math.max(width, painter.width);
      }
      painter.dispose();
      return width;
    }, [node, style, direction, scaler, locale]);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < node.items.length; i++)
          _MarkdownListItem(
            item: node.items[i],
            marker: labels[i],
            markerWidth: markerWidth,
            sheet: sheet,
            renderContext: renderContext,
          ),
      ],
    );
  }
}

class _MarkdownListItem extends ConsumerWidget {
  const _MarkdownListItem({
    required this.item,
    required this.marker,
    required this.markerWidth,
    required this.sheet,
    required this.renderContext,
  });

  final ListItemNode item;
  final String marker;
  final double markerWidth;
  final MarkdownStyleSheet sheet;
  final MarkdownRenderContext renderContext;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final content = item.children.where((node) => node is! ListNode).toList();
    final nested = item.children.whereType<ListNode>();
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: markerWidth,
              child: Align(
                alignment: AlignmentDirectional.topEnd,
                child: switch (item.checked) {
                  final checked? => AppIcon(
                    checked ? AppIcons.checked : AppIcons.unchecked,
                    size: AppMarkdownTheme.taskMarkerSize,
                    color: sheet.textStyle?.color,
                  ),
                  null => Text(marker, style: sheet.listBulletStyle),
                },
              ),
            ),
            const Gap(AppMarkdownTheme.listMarkerGap),
            Expanded(
              child:
                  renderContext.inlineRenderer?.call(
                    content,
                    sheet.textStyle,
                  ) ??
                  MarkdownRenderer(styleSheet: sheet)
                      .renderInline(content, sheet.textStyle, renderContext),
            ),
          ],
        ),
        // A nested marker begins where the parent's body begins. The parent
        // row has already consumed its marker column and the marker gap.
        for (final list in nested)
          Padding(
            padding: EdgeInsetsDirectional.only(
              start: markerWidth + AppMarkdownTheme.listMarkerGap,
              top: AppSpacing.xxs,
            ),
            child: _MarkdownList(
              node: list,
              sheet: sheet,
              renderContext: renderContext.copyWith(
                listLevel: renderContext.listLevel + 1,
              ),
            ),
          ),
      ],
    );
  }
}
