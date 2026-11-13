import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:image/image.dart' as img;
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:selfbox/core/router/app_router.dart';
import 'package:selfbox/core/router/app_routes.dart';
import 'package:selfbox/core/testing/app_widget_tester.dart';
import 'package:selfbox/core/testing/fake_message_repository.dart';
import 'package:selfbox/core/testing/temp_storage.dart';
import 'package:selfbox/core/theme/app_glass_theme.dart';
import 'package:selfbox/features/chat/domain/models/message.dart';
import 'package:selfbox/features/chat/presentation/widgets/image_viewer_thumbnail.dart';
import 'package:selfbox/features/settings/domain/models/app_preferences.dart';

const _pages = ValueKey('image-viewer-pages');
const _strip = ValueKey('image-viewer-thumbnails');
const _selected = ValueKey('image-viewer-selected-thumbnail');

void _expectCentered(WidgetTester tester) {
  expect(
    tester.getCenter(find.byKey(_selected)).dx,
    closeTo(tester.getCenter(find.byKey(_strip)).dx, 0.5),
  );
  final border = tester.widget<DecoratedBox>(find.byKey(_selected));
  expect(border.position, DecorationPosition.foreground);
  final decoration = border.decoration as BoxDecoration;
  expect(decoration.border?.top.width, greaterThanOrEqualTo(2));
  expect(decoration.border?.top.color.a, greaterThan(0.8));
}

Future<GoRouter> _open(WidgetTester tester, {bool animations = true}) async {
  final container = await tester.pumpApp(
    initialPreferences: AppPreferences(animationsEnabled: animations),
    messages: FakeMessageRepository(
      seed: [
        Message(
          id: 1,
          createdAt: kTestNow,
          author: MessageAuthor.me,
          text: '',
          images: const ['media/a.jpg', 'media/b.jpg', 'media/c.jpg'],
        ),
      ],
    ),
  );
  final router = container.read(appRouterProvider);
  unawaited(router.push(const ImageViewerRoute(path: 'media/c.jpg').location));
  await tester.pumpAndSettle();
  return router;
}

void main() {
  for (final animations in [true, false]) {
    testWidgets(
      'gallery stops at both ends, centers and resizes with animations=$animations',
      (tester) async {
        await _open(tester, animations: animations);
        _expectCentered(tester);
        expect(
          find.ancestor(
            of: find.byKey(_strip),
            matching: find.byType(GlassContainer),
          ),
          findsNothing,
        );
        expect(find.text('3 / 3'), findsOneWidget);
        await tester.drag(find.byKey(_pages), const Offset(-300, 0));
        await tester.pumpAndSettle();
        expect(find.text('3 / 3'), findsOneWidget);
        _expectCentered(tester);
        await tester.drag(find.byKey(_pages), const Offset(300, 0));
        await tester.pumpAndSettle();
        expect(find.text('2 / 3'), findsOneWidget);
        await tester.drag(find.byKey(_pages), const Offset(300, 0));
        await tester.pumpAndSettle();
        expect(find.text('1 / 3'), findsOneWidget);
        await tester.drag(find.byKey(_pages), const Offset(300, 0));
        await tester.pumpAndSettle();
        expect(find.text('1 / 3'), findsOneWidget);
        await tester.drag(find.byKey(_pages), const Offset(-300, 0));
        await tester.pumpAndSettle();
        expect(find.text('2 / 3'), findsOneWidget);
        await tester.drag(find.byKey(_strip), const Offset(-72, 0));
        await tester.pumpAndSettle();
        expect(find.text('3 / 3'), findsOneWidget);
        await tester.drag(find.byKey(_strip), const Offset(-150, 0));
        await tester.pumpAndSettle();
        expect(find.text('3 / 3'), findsOneWidget);
        await tester.drag(find.byKey(_strip), const Offset(150, 0));
        await tester.pumpAndSettle();
        await tester.drag(find.byKey(_strip), const Offset(150, 0));
        await tester.pumpAndSettle();
        expect(find.text('1 / 3'), findsOneWidget);
        _expectCentered(tester);
        final current = tester.widget<ImageViewerThumbnail>(
          find.ancestor(
            of: find.byKey(_selected),
            matching: find.byType(ImageViewerThumbnail),
          ),
        );
        final count =
            [
              'media/a.jpg',
              'media/b.jpg',
              'media/c.jpg',
            ].indexOf(current.path) +
            1;
        expect(find.text('$count / 3'), findsOneWidget);
        tester.view.physicalSize = const Size(280 * 3, 640 * 3);
        await tester.pumpAndSettle();
        _expectCentered(tester);
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final brightness in Brightness.values) {
    testWidgets(
      'decoded full-screen photo leaves an isolated readable close control in $brightness',
      (tester) async {
        tester.platformDispatcher.platformBrightnessTestValue = brightness;
        addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
        final paths = createTempAppPaths();
        final file = File('${paths.root.path}/media/bright.png');
        await tester.runAsync(() async {
          await file.parent.create(recursive: true);
          await file.writeAsBytes(
            img.encodePng(
              img.Image(width: 390, height: 844)
                ..clear(img.ColorRgb8(255, 255, 255)),
            ),
          );
          final ready = Completer<void>();
          final stream = FileImage(file).resolve(ImageConfiguration.empty);
          final listener = ImageStreamListener(
            (_, _) => ready.complete(),
            onError: ready.completeError,
          );
          stream.addListener(listener);
          await ready.future;
          stream.removeListener(listener);
        });
        final container = await tester.pumpApp(paths: paths);
        final router = container.read(appRouterProvider);
        unawaited(
          router.push(
            const ImageViewerRoute(path: 'media/bright.png').location,
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byType(RawImage), findsWidgets);
        final close = find.byKey(const ValueKey('image-viewer-close'));
        final button = tester.widget<GlassIconButton>(close);
        expect(button.useOwnLayer, isTrue);
        expect(button.settings?.glassColor, AppGlassTheme.dark.chromeTint);
        final zoom = tester.widget<InteractiveViewer>(
          find.byType(InteractiveViewer).first,
        );
        zoom.transformationController!.value = Matrix4.diagonal3Values(3, 3, 1);
        await tester.pumpAndSettle();
        expect(close.hitTestable(), findsOneWidget);
        expect(tester.getSize(close), const Size(48, 48));
        await tester.tap(close);
        await tester.pumpAndSettle();
        expect(router.state.matchedLocation, '/chat');
        expect(tester.takeException(), isNull);
      },
    );
  }
}
