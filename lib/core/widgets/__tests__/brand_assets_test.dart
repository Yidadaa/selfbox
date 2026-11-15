import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:selfbox/core/testing/app_widget_tester.dart';
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

  test('full logo fills runtime and native icon resources', () {
    final source = img.decodePng(
      File('docs/design/asset-kit/logo/logo-full.png').readAsBytesSync(),
    );
    expect(source, isNotNull);
    if (source == null) return;
    for (final (path, size) in [
      ('assets/brand/logo.png', 512),
      ('android/app/src/main/res/mipmap-mdpi/ic_launcher.png', 48),
      ('android/app/src/main/res/mipmap-hdpi/ic_launcher.png', 72),
      ('android/app/src/main/res/mipmap-xhdpi/ic_launcher.png', 96),
      ('android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png', 144),
      ('android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png', 192),
      (
        'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png',
        1024,
      ),
      ('macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_512.png', 512),
    ]) {
      final actual = img.decodePng(File(path).readAsBytesSync());
      expect(actual, isNotNull, reason: path);
      if (actual == null) continue;
      final expected = img.copyResize(
        source,
        width: size,
        height: size,
        interpolation: img.Interpolation.cubic,
      );
      expect(actual.width, size, reason: path);
      expect(actual.height, size, reason: path);
      if (path == 'assets/brand/logo.png') expect(actual.hasAlpha, isTrue);
      if (size == 1024) expect(actual.getPixel(0, 0).a, 255);
      expect(
        actual.convert(numChannels: 3).getBytes(),
        expected.convert(numChannels: 3).getBytes(),
        reason: path,
      );
    }
    final foreground = img.decodePng(
      File('android/app/src/main/res/drawable-nodpi/ic_launcher_foreground.png')
          .readAsBytesSync(),
    );
    expect(foreground, isNotNull);
    if (foreground == null) return;
    expect(foreground.width, 432);
    expect(foreground.height, 432);
    expect(foreground.getPixel(0, 0).a, 0);
    final expectedForeground = img.copyResize(
      source,
      width: 288,
      height: 288,
      interpolation: img.Interpolation.cubic,
    );
    expect(
      img
          .copyCrop(foreground, x: 72, y: 72, width: 288, height: 288)
          .convert(numChannels: 3)
          .getBytes(),
      expectedForeground.convert(numChannels: 3).getBytes(),
    );
  });
  test('runtime brand assets and native launcher icons are prepared', () {
    for (final (name, size) in [
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
  }
}
