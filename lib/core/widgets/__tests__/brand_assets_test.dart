import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:selfbox/core/router/app_router.dart';
import 'package:selfbox/core/testing/app_widget_tester.dart';
import 'package:selfbox/core/testing/fake_memory_repository.dart';
import 'package:selfbox/core/theme/app_glass_theme.dart';
import 'package:selfbox/features/settings/presentation/widgets/profile_avatar.dart';
import 'package:selfbox/gen/i18n/strings.g.dart';

Finder artwork(String name) => find.byWidgetPredicate((widget) {
  if (widget is! Image) return false;
  final provider = widget.image;
  final asset = provider is ResizeImage ? provider.imageProvider : provider;
  return asset is AssetImage && asset.assetName == 'assets/brand/$name.png';
});

void main() {
  test('app uses 小懒 in both locales and native launch labels', () async {
    for (final locale in AppLocale.values) {
      expect((await locale.build()).app.name, '小懒');
    }
    expect(
      File('android/app/src/main/AndroidManifest.xml').readAsStringSync(),
      contains('android:label="小懒"'),
    );
    expect(
      File('ios/Runner/Info.plist').readAsStringSync(),
      contains('<string>小懒</string>'),
    );
  });

  test('launcher backgrounds fade vertically from coordinated blue to white', () {
    for (final path in [
      'android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png',
      'android/app/src/main/res/drawable-nodpi/ic_launcher_background.png',
      'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png',
      'macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_512.png',
    ]) {
      final image = img.decodePng(File(path).readAsBytesSync());
      expect(image, isNotNull);
      if (image == null) continue;
      final top = image.getPixel(0, 0);
      final middle = image.getPixel(0, image.height ~/ 2);
      final bottom = image.getPixel(0, image.height - 1);
      expect([top.r, top.g, top.b, top.a], [140, 185, 238, 255]);
      expect(middle.r, greaterThan(top.r));
      expect(middle.r, lessThan(bottom.r));
      expect([bottom.r, bottom.g, bottom.b, bottom.a], [255, 255, 255, 255]);
    }
    expect(
      File('android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml')
          .readAsStringSync(),
      contains('@drawable/ic_launcher_background'),
    );
  });
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
        final background =
            tester
                    .widget<DecoratedBox>(
                      find.byKey(const ValueKey('default-avatar-surface')),
                    )
                    .decoration
                as BoxDecoration;
        expect(background.shape, BoxShape.circle);
        expect(background.color, AppGlassTheme.of(brightness).bubbleOther);
        expect(background.color?.a, 1);
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
      ('/me/about', 'logo', '小懒'),
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
