import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:selfbox/core/router/app_router.dart';
import 'package:selfbox/core/testing/app_widget_tester.dart';
import 'package:selfbox/core/testing/fake_message_repository.dart';
import 'package:selfbox/core/testing/icon_finder.dart';
import 'package:selfbox/core/theme/app_glass_theme.dart';
import 'package:selfbox/core/theme/app_icons.dart';
import 'package:selfbox/core/widgets/pressable.dart';
import 'package:selfbox/features/chat/domain/models/message.dart';
import 'package:selfbox/features/chat/presentation/pages/image_viewer_page.dart';
import 'package:selfbox/features/chat/presentation/widgets/image_viewer_thumbnail.dart';
import 'package:selfbox/features/chat/presentation/widgets/message_bubble.dart';
import 'package:selfbox/gen/i18n/strings.g.dart';

import 'chat_page_test_support.dart';

Message _message(int id, List<String> images) => Message(
  id: id,
  createdAt: DateTime(2026, 11, 12, id),
  author: MessageAuthor.me,
  text: '',
  images: images,
);

void main() {
  final history = FakeMessageRepository(
    seed: [
      _message(1, ['media/a.jpg']),
      _message(2, ['media/b.jpg']),
      _message(3, ['media/c.jpg']),
    ],
  );

  testWidgets('thumbnail taps jump directly to the selected historical image', (
    tester,
  ) async {
    await tester.pumpPage(
      const ImageViewerPage(path: 'media/c.jpg'),
      messages: history,
    );

    expect(find.text('3 / 3'), findsOneWidget);
    final firstThumbnail = find
        .byWidgetPredicate(
          (widget) =>
              widget is ImageViewerThumbnail && widget.path == 'media/a.jpg',
        )
        .first;
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
      await tester.drag(
        find.byKey(const ValueKey('image-viewer-pages')),
        const Offset(-300, 0),
      );
      await tester.pumpAndSettle();
    }

    expect(find.text('17 / 24'), findsOneWidget);
    final selected = find.byKey(
      const ValueKey('image-viewer-selected-thumbnail'),
    );
    final strip = find.byKey(const ValueKey('image-viewer-thumbnails'));
    final selectedRect = tester.getRect(selected);
    final stripRect = tester.getRect(strip);
    expect(selectedRect.left, greaterThanOrEqualTo(stripRect.left));
    expect(selectedRect.right, lessThanOrEqualTo(stripRect.right));
  });

  testWidgets('tapping an image opens the full-screen viewer', (tester) async {
    final container = await tester.pumpApp(
      messages: FakeMessageRepository(
        seed: [
          testMessage(1, '', images: ['media/missing.jpg']),
        ],
      ),
    );

    await tester.tap(
      find.descendant(
        of: find.byType(MessageBubble),
        matching: find.byType(Pressable),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(ImageViewerPage), findsOneWidget);
    expect(
      container.read(appRouterProvider).state.uri.toString(),
      '/image?path=media%2Fmissing.jpg',
    );
  });

  testWidgets('unavailable image uses readable text on the dark viewer', (
    tester,
  ) async {
    final container = await tester.pumpApp();
    container.read(appRouterProvider).go('/image?path=outside.jpg');
    await tester.pumpAndSettle();

    final label = find.text(t.chat.imageFailed);
    expect(label, findsOneWidget);
    expect(
      tester.widget<Text>(label).style?.color,
      AppGlassTheme.dark.foregroundMuted,
    );
    expect(findAppIcon(AppIcons.imageUnavailable), findsNothing);
  });
}
