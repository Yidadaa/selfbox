import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:selfbox/core/error/app_failure.dart';
import 'package:selfbox/core/testing/app_widget_tester.dart';
import 'package:selfbox/core/testing/fake_message_repository.dart';
import 'package:selfbox/core/testing/temp_storage.dart';
import 'package:selfbox/core/theme/app_glass_theme.dart';
import 'package:selfbox/core/theme/app_icons.dart';
import 'package:selfbox/core/theme/message_tokens.dart';
import 'package:selfbox/core/widgets/app_artwork.dart';
import 'package:selfbox/core/widgets/app_icon.dart';
import 'package:selfbox/features/chat/presentation/pages/image_viewer_page.dart';
import 'package:selfbox/features/chat/presentation/providers/message_search.dart';
import 'package:selfbox/features/chat/presentation/widgets/message_image_stack.dart';
import 'package:selfbox/gen/i18n/strings.g.dart';

import 'chat_page_test_support.dart';

void main() {
  testWidgets('search resolves stored images and opens the image viewer', (
    tester,
  ) async {
    final paths = createTempAppPaths();
    paths.media.createSync(recursive: true);
    final file = File('tool/screenshots/assets/aurora.png')
        .copySync('${paths.media.path}${Platform.pathSeparator}hike.jpg');
    await tester.runAsync(() async {
      final done = Completer<void>();
      final provider = ResizeImage.resizeIfNeeded(
        kBubbleImageDecodeWidth,
        null,
        FileImage(file),
      );
      final stream = provider.resolve(ImageConfiguration.empty);
      final listener = ImageStreamListener(
        (_, _) => done.complete(),
        onError: done.completeError,
      );
      stream.addListener(listener);
      await done.future;
      stream.removeListener(listener);
    });
    await tester.pumpApp(
      paths: paths,
      messages: FakeMessageRepository(
        seed: [
          testMessage(
            1,
            'photo from hike',
          ).copyWith(images: ['media/hike.jpg']),
        ],
      ),
    );
    await tester.tap(find.bySemanticsLabel(t.chat.searchMessages));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('message-search-input')),
      'hike',
    );
    await tester.pumpAndSettle();
    final stack = tester.widget<MessageImageStack>(
      find.byType(MessageImageStack),
    );
    final image = tester.widget<RawImage>(
      find.descendant(
        of: find.byType(MessageImageStack),
        matching: find.byType(RawImage),
      ),
    );
    expect(image.image, isNotNull);
    expect(stack.resolveImage('media/hike.jpg')?.path, contains('hike.jpg'));
    expect(stack.resolveImage('../outside.jpg'), isNull);
    await tester.tap(find.byType(MessageImageStack));
    await tester.pumpAndSettle();
    expect(find.byType(ImageViewerPage), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  for (final brightness in Brightness.values) {
    testWidgets(
      'search field icon uses neutral theme foreground in $brightness',
      (tester) async {
        tester.platformDispatcher.platformBrightnessTestValue = brightness;
        addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
        await tester.pumpApp();
        await tester.tap(find.bySemanticsLabel(t.chat.searchMessages));
        await tester.pumpAndSettle();
        final input = find.byKey(const ValueKey('message-search-input'));
        final icon = tester.widget<AppIcon>(
          find.descendant(
            of: input,
            matching: find.byWidgetPredicate(
              (w) => w is AppIcon && w.icon == AppIcons.search,
            ),
          ),
        );
        expect(icon.color, tester.element(input).glass.foregroundMuted);
      },
    );
  }
  for (final (locale, prompt, emptyLabel) in [
    (AppLocale.en, 'Search your thoughts', 'No messages found'),
    (AppLocale.zhCn, '搜索你的碎碎念', '没有搜索到消息'),
  ]) {
    testWidgets(
      'message search filters notes and shows localized empty states in $locale',
      (tester) async {
        await tester.pumpApp(
          locale: locale,
          messages: FakeMessageRepository(
            seed: [
              testMessage(1, 'weekly report'),
              testMessage(2, 'weekend hike'),
            ],
          ),
        );
        await tester.tap(find.bySemanticsLabel(t.chat.searchMessages));
        await tester.pumpAndSettle();
        expect(find.text(prompt), findsOneWidget);
        expect(
          find.byWidgetPredicate(
            (widget) =>
                widget is AppArtwork && widget.artwork == BrandArt.search,
          ),
          findsOneWidget,
        );

        await tester.enterText(
          find.byKey(const ValueKey('message-search-input')),
          'report',
        );
        await tester.pumpAndSettle();
        expect(find.text('weekly report'), findsOneWidget);
        expect(find.text('weekend hike'), findsNothing);

        await tester.enterText(
          find.byKey(const ValueKey('message-search-input')),
          'missing phrase',
        );
        await tester.pumpAndSettle();
        expect(find.text(t.chat.noSearchResults), findsOneWidget);
        expect(find.text(emptyLabel), findsOneWidget);
      },
    );
  }

  testWidgets('message search failures offer a retry action', (tester) async {
    await tester.pumpApp(
      overrides: [
        messageSearchProvider('broken').overrideWith(
          (ref) async =>
              const Left(AppFailure.database(message: 'unavailable')),
        ),
      ],
    );
    await tester.tap(find.bySemanticsLabel(t.chat.searchMessages));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('message-search-input')),
      'broken',
    );
    await tester.pumpAndSettle();

    expect(find.text(t.settings.errors.generic), findsOneWidget);
    expect(find.text(t.common.retry), findsOneWidget);
  });
}
