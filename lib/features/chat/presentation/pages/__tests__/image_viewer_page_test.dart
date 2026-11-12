import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:selfbox/core/testing/app_widget_tester.dart';
import 'package:selfbox/features/chat/presentation/pages/image_viewer_page.dart';

void main() {
  testWidgets('album opens selected image and swipes between pages', (
    tester,
  ) async {
    await tester.pumpPage(
      const ImageViewerPage(
        path: 'invalid-b',
        paths: ['invalid-a', 'invalid-b', 'invalid-c'],
      ),
    );
    expect(find.text('2 / 3'), findsOneWidget);
    await tester.drag(find.byType(PageView), const Offset(-300, 0));
    await tester.pumpAndSettle();
    expect(find.text('3 / 3'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
