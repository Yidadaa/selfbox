import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:selfbox/core/router/app_router.dart';
import 'package:selfbox/features/chat/domain/models/message.dart';

import '../../../../support/app_widget_tester.dart';
import '../../../../support/fake_message_repository.dart';

void main() {
  testWidgets(
    'adding a second finger during a drag cancels paging and pinches',
    (tester) async {
      final container = await tester.pumpApp(
        messages: FakeMessageRepository(
          seed: [
            Message(
              id: 1,
              createdAt: kTestNow,
              author: MessageAuthor.me,
              text: '',
              images: const ['media/a.jpg', 'media/b.jpg'],
            ),
          ],
        ),
      );
      unawaited(
        container.read(appRouterProvider).push('/image?path=media%2Fa.jpg'),
      );
      await tester.pumpAndSettle();
      final viewer = find.byType(InteractiveViewer).first;
      final center = tester.getCenter(viewer);
      final first = await tester.startGesture(
        center - const Offset(30, 0),
        pointer: 1,
      );
      await first.moveBy(const Offset(-35, 0));
      await tester.pump();
      final second = await tester.startGesture(
        center + const Offset(30, 0),
        pointer: 2,
      );
      for (var step = 1; step <= 10; step++) {
        await first.moveBy(const Offset(-6, 0));
        await second.moveBy(const Offset(6, 0));
        await tester.pump();
      }
      await first.up();
      await second.up();
      await tester.pumpAndSettle();
      expect(find.text('1 / 2'), findsOneWidget);
      expect(
        tester
            .widget<InteractiveViewer>(viewer)
            .transformationController!
            .value
            .getMaxScaleOnAxis(),
        greaterThan(1.5),
      );
    },
  );
  testWidgets('pinch owns the gallery gesture; double tap restores fit', (
    tester,
  ) async {
    final container = await tester.pumpApp(
      messages: FakeMessageRepository(
        seed: [
          Message(
            id: 1,
            createdAt: kTestNow,
            author: MessageAuthor.me,
            text: '',
            images: const ['media/a.jpg', 'media/b.jpg'],
          ),
        ],
      ),
    );
    unawaited(
      container.read(appRouterProvider).push('/image?path=media%2Fa.jpg'),
    );
    await tester.pumpAndSettle();
    final viewer = find.byType(InteractiveViewer).first;
    final center = tester.getCenter(viewer);
    final left = await tester.startGesture(
      center - const Offset(30, 0),
      pointer: 1,
    );
    final right = await tester.startGesture(
      center + const Offset(30, 0),
      pointer: 2,
    );
    for (var step = 1; step <= 8; step++) {
      await left.moveTo(center - Offset(30 + step * 6, 0));
      await right.moveTo(center + Offset(30 + step * 6, 0));
      await tester.pump();
    }
    await left.up();
    await right.up();
    await tester.pumpAndSettle();
    double scale() => tester
        .widget<InteractiveViewer>(viewer)
        .transformationController!
        .value
        .getMaxScaleOnAxis();
    expect(scale(), greaterThan(1.5));
    expect(find.text('1 / 2'), findsOneWidget);
    await tester.tapAt(center);
    await tester.pump(const Duration(milliseconds: 80));
    await tester.tapAt(center);
    await tester.pumpAndSettle();
    expect(scale(), closeTo(1, 0.001));
    await tester.pump(const Duration(milliseconds: 350));
    await tester.tapAt(center);
    await tester.pump(const Duration(milliseconds: 80));
    await tester.tapAt(center);
    await tester.pumpAndSettle();
    expect(scale(), greaterThan(2));
    await tester.longPress(viewer);
    await tester.pumpAndSettle();
    expect(find.byType(BottomSheet), findsNothing);
    expect(scale(), greaterThan(2));
    await tester.drag(viewer, const Offset(-200, 0));
    await tester.pumpAndSettle();
    expect(find.text('1 / 2'), findsOneWidget);
  });
}
