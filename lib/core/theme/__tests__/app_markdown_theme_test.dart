import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:selfbox/core/theme/app_markdown_theme.dart';
import 'package:selfbox/core/theme/app_theme.dart';

void main() {
  for (final brightness in Brightness.values) {
    testWidgets('$brightness keeps all Markdown headings close to body size', (
      tester,
    ) async {
      late List<TextStyle?> headings;
      late TextStyle? paragraph;
      late List<TextStyle?> thinkingHeadings;
      await tester.pumpWidget(
        MaterialApp(
          theme: brightness == Brightness.dark
              ? AppTheme.dark()
              : AppTheme.light(),
          home: Builder(
            builder: (context) {
              final normal = AppMarkdownTheme.of(context);
              final thinking = AppMarkdownTheme.of(context, thinking: true);
              paragraph = normal.paragraphStyle;
              headings = [
                normal.h1Style,
                normal.h2Style,
                normal.h3Style,
                normal.h4Style,
                normal.h5Style,
                normal.h6Style,
              ];
              thinkingHeadings = [
                thinking.h1Style,
                thinking.h2Style,
                thinking.h3Style,
                thinking.h4Style,
                thinking.h5Style,
                thinking.h6Style,
              ];
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      final bodySize = paragraph!.fontSize!;
      for (final heading in headings) {
        expect(heading!.fontSize, greaterThan(bodySize));
        expect(heading.fontSize, lessThanOrEqualTo(bodySize + 2));
        expect(heading.fontWeight, FontWeight.w600);
        expect(heading.color, paragraph!.color);
      }
      for (final heading in thinkingHeadings) {
        expect(heading!.fontSize, bodySize);
        expect(heading.fontWeight, FontWeight.w600);
      }
    });
  }
}
