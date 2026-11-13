import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_smooth_markdown/flutter_smooth_markdown.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../theme/app_markdown_theme.dart';
import '../theme/app_spacing.dart';

BuilderRegistry appMarkdownBuilders() =>
    BuilderRegistry()..register('list', const _ListBuilder());

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

class _MarkdownList extends ConsumerWidget {
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
    final painter = TextPainter(
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      locale: Localizations.maybeLocaleOf(context),
    );
    // A shared marker column keeps 9. / 10. and wrapped text aligned.
    var markerWidth = 0.0;
    for (var i = 0; i < node.items.length; i++) {
      painter.text = TextSpan(text: labels[i], style: style);
      painter.layout();
      final width = node.items[i].checked == null
          ? painter.width
          : AppMarkdownTheme.taskMarkerSize;
      markerWidth = math.max(markerWidth, width);
    }
    painter.dispose();
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
                  final checked? => Icon(
                    checked ? Icons.check_box : Icons.check_box_outline_blank,
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
