import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:selfbox/core/router/app_router.dart';
import 'package:selfbox/core/testing/app_widget_tester.dart';
import 'package:selfbox/core/testing/fake_memory_repository.dart';
import 'package:selfbox/features/settings/presentation/widgets/profile_avatar.dart';
import 'package:selfbox/gen/i18n/strings.g.dart';

Finder artwork(String name) => find.byWidgetPredicate((widget) {
  if (widget is! Image) return false;
  final provider = widget.image;
  final asset = provider is ResizeImage ? provider.imageProvider : provider;
  return asset is AssetImage && asset.assetName == 'assets/brand/$name.png';
});

void main() {
  test('runtime brand assets and native launcher icons are prepared', () {
    for (final (name, size) in [
      ('logo', 512),
      ('avatar-default', 256),
      ('empty-welcome', 768),
      ('empty-files', 768),
      ('empty-search', 768),
      ('feedback-error', 512),
      ('small-empty', 192),
    ]) {
      final file = File('assets/brand/$name.png');
      expect(file.existsSync(), isTrue, reason: name);
      final image = img.decodePng(file.readAsBytesSync());
      expect(image?.width, size);
      expect(image?.height, size);
      expect(image?.hasAlpha, isTrue);
    }
    final android = img.decodePng(
      File('android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png')
          .readAsBytesSync(),
    );
    expect(android?.width, 192);
    final ios = img.decodePng(
      File(
        'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png',
      ).readAsBytesSync(),
    );
    expect(ios?.width, 1024);
    expect(ios?.getPixel(0, 0).a, 255);
    expect(
      File('android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml')
          .existsSync(),
      isTrue,
    );
  });

  for (final brightness in Brightness.values) {
    testWidgets(
      'default avatar uses the dog without clipping ears in ${brightness.name}',
      (tester) async {
        await tester.pumpPage(const ProfileAvatar(), brightness: brightness);
        expect(artwork('avatar-default'), findsOneWidget);
        expect(
          tester.widget<Image>(artwork('avatar-default')).fit,
          BoxFit.contain,
        );
      },
    );

    for (final (route, image, label) in [
      ('/chat', 'empty-welcome', ''),
      ('/memory', 'empty-files', ''),
      ('/chat/search', 'empty-search', ''),
      ('/me/about', 'logo', 'Selfbox'),
      ('/missing-brand-page', 'state-resting', ''),
    ]) {
      testWidgets('$route uses $image in ${brightness.name}', (tester) async {
        tester.platformDispatcher.platformBrightnessTestValue = brightness;
        addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
        final container = await tester.pumpApp(memory: FakeMemoryRepository());
        container.read(appRouterProvider).go(route);
        await tester.pumpAndSettle();
        expect(artwork(image), findsOneWidget);
        if (label.isNotEmpty) expect(find.text(label), findsOneWidget);
        if (route == '/memory') {
          expect(find.text(t.memory.empty), findsOneWidget);
        }
        expect(tester.takeException(), isNull);
      });
    }
  }
}
