import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:selfbox/core/router/app_router.dart';
import 'package:selfbox/core/router/app_routes.dart';
import 'package:selfbox/core/testing/app_widget_tester.dart';
import 'package:selfbox/core/testing/fake_message_repository.dart';
import 'package:selfbox/features/chat/domain/models/message.dart';
import 'package:selfbox/features/chat/presentation/pages/image_viewer_page.dart';

void main() {
  final history = FakeMessageRepository(
    seed: [
      _message(1, ['media/a.jpg']),
      _message(2, ['media/b.jpg']),
      _message(3, ['media/c.jpg']),
    ],
  );

  testWidgets('viewer swipes across images from the full message history', (
    tester,
  ) async {
    await tester.pumpPage(
      const ImageViewerPage(path: 'media/b.jpg'),
      messages: history,
    );
    expect(find.text('2 / 3'), findsOneWidget);
    await tester.drag(find.byType(PageView), const Offset(-300, 0));
    await tester.pumpAndSettle();
    expect(find.text('3 / 3'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('thumbnail taps jump directly to the selected historical image', (
    tester,
  ) async {
    await tester.pumpPage(
      const ImageViewerPage(path: 'media/c.jpg'),
      messages: history,
    );

    expect(find.text('3 / 3'), findsOneWidget);
    final firstThumbnail = find.byKey(
      const ValueKey('image-thumbnail-media/a.jpg'),
    );
    await tester.ensureVisible(firstThumbnail);
    await tester.tap(firstThumbnail);
    await tester.pumpAndSettle();

    expect(find.text('1 / 3'), findsOneWidget);
  });

  testWidgets('selected thumbnail stays visible while browsing long history', (
    tester,
  ) async {
    final longHistory = FakeMessageRepository(
      seed: List.generate(
        24,
        (index) => _message(index + 1, ['media/image-$index.jpg']),
      ),
    );
    await tester.pumpPage(
      const ImageViewerPage(path: 'media/image-0.jpg'),
      messages: longHistory,
    );

    for (var index = 0; index < 16; index++) {
      await tester.drag(find.byType(PageView), const Offset(-300, 0));
      await tester.pumpAndSettle();
    }

    expect(find.text('17 / 24'), findsOneWidget);
    final selected = find.byKey(
      const ValueKey('image-thumbnail-media/image-16.jpg'),
    );
    final strip = find.byKey(const ValueKey('image-viewer-thumbnails'));
    final selectedRect = tester.getRect(selected);
    final stripRect = tester.getRect(strip);
    expect(selectedRect.left, greaterThanOrEqualTo(stripRect.left));
    expect(selectedRect.right, lessThanOrEqualTo(stripRect.right));
  });

  testWidgets('close control remains visible and pops the viewer route', (
    tester,
  ) async {
    final container = await tester.pumpApp();
    final router = container.read(appRouterProvider);
    const route = ImageViewerRoute(path: 'media/current.jpg');
    unawaited(router.push(route.location, extra: ['media/current.jpg']));
    await tester.pumpAndSettle();

    final close = find.byKey(const ValueKey('image-viewer-close'));
    expect(close, findsOneWidget);
    expect(close.hitTestable(), findsOneWidget);
    await tester.tap(close);
    await tester.pumpAndSettle();

    expect(router.state.matchedLocation, '/chat');
  });
}

Message _message(int id, List<String> images) => Message(
  id: id,
  createdAt: DateTime(2026, 11, 12, id),
  author: MessageAuthor.me,
  text: '',
  images: images,
);
