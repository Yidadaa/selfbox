import 'package:flutter/material.dart';
import 'package:flutter_smooth_markdown/flutter_smooth_markdown.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:selfbox/core/testing/app_widget_tester.dart';
import 'package:selfbox/core/theme/app_markdown_theme.dart';
import 'package:selfbox/core/widgets/app_markdown_builders.dart';

const _nested = '''
- Level one
  - Level two
    - Level three
      - Level four with enough text to wrap onto another line
''';

void main() {
  for (final brightness in Brightness.values) {
    for (final streaming in [false, true]) {
      testWidgets(
        '$brightness streaming=$streaming nests markers at the parent marker edge',
        (tester) async {
          await tester.pumpPage(
            _MarkdownFixture(data: _nested, streaming: streaming),
            brightness: brightness,
          );
          await tester.pump(const Duration(milliseconds: 100));

          final markers = find.byWidgetPredicate(
            (widget) => widget is Text && widget.data?.trim() == '•',
          );
          expect(markers, findsNWidgets(4));
          final rects = [
            for (var i = 0; i < 4; i++) tester.getRect(markers.at(i)),
          ];
          for (var i = 1; i < rects.length; i++) {
            expect(
              rects[i].left,
              closeTo(rects[i - 1].right, 0.01),
              reason: 'Level ${i + 1} must not add depth-based padding.',
            );
          }
          final firstBody = tester.getRect(
            find.text('Level one', findRichText: true),
          );
          expect(rects[1].left, lessThan(firstBody.left));
          final lastBody = tester.getRect(
            find.text(
              'Level four with enough text to wrap onto another line',
              findRichText: true,
            ),
          );
          expect(lastBody.height, greaterThan(firstBody.height));
          expect(lastBody.right, lessThanOrEqualTo(390));
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  testWidgets('ordered markers share a right edge across digit counts', (
    tester,
  ) async {
    await tester.pumpPage(
      const _MarkdownFixture(data: '9. Ninth\n10. Tenth\n11. Eleventh'),
    );
    final markers = find.byWidgetPredicate(
      (widget) =>
          widget is Text &&
          const ['9.', '10.', '11.'].contains(widget.data?.trim()),
    );
    expect(markers, findsNWidgets(3));
    final right = tester.getRect(markers.first).right;
    for (var i = 1; i < 3; i++) {
      expect(tester.getRect(markers.at(i)).right, closeTo(right, 0.01));
    }
    expect(
      tester.getTopLeft(find.text('Ninth', findRichText: true)).dx,
      tester.getTopLeft(find.text('Tenth', findRichText: true)).dx,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('mixed task lists preserve check states and inline formatting', (
    tester,
  ) async {
    await tester.pumpPage(
      const _MarkdownFixture(
        data:
            '- [x] **Done**\n  1. [Guide](https://example.com)\n'
            '     - [ ] Pending',
      ),
    );
    expect(find.byIcon(Icons.check_box), findsOneWidget);
    expect(find.byIcon(Icons.check_box_outline_blank), findsOneWidget);
    expect(find.text('Done', findRichText: true), findsOneWidget);
    expect(find.text('Guide', findRichText: true), findsOneWidget);
    expect(find.text('Pending', findRichText: true), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _MarkdownFixture extends StatelessWidget {
  const _MarkdownFixture({required this.data, this.streaming = false});

  final String data;
  final bool streaming;

  @override
  Widget build(BuildContext context) {
    final sheet = AppMarkdownTheme.of(context, thinking: streaming);
    return Scaffold(
      body: Center(
        child: SizedBox(
          width: 280,
          child: streaming
              ? StreamMarkdown(
                  stream: Stream.value(data),
                  styleSheet: sheet,
                  builderRegistry: appMarkdownBuilders(),
                )
              : SmoothMarkdown(
                  data: data,
                  styleSheet: sheet,
                  builderRegistry: appMarkdownBuilders(),
                ),
        ),
      ),
    );
  }
}
