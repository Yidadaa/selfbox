import 'dart:convert';
import 'dart:io';

import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;

final _root = p.dirname(p.dirname(Platform.script.toFilePath()));
final _kit = p.join(_root, 'docs/design/asset-kit');

void main() {
  final manifest = jsonDecode(
    File(p.join(_kit, 'manifest.json')).readAsStringSync(),
  ) as Map<String, Object?>;
  final entries = manifest['assets']! as List<Object?>;
  for (final value in entries) {
    final asset = value! as Map<String, Object?>;
    final category = asset['category']! as String;
    final size = switch (category) {
      'large' => 768,
      'avatar' => 256,
      'small' => 192,
      'medium' || 'states' => 512,
      _ => throw StateError('Unknown asset category: $category'),
    };
    _png(
      'assets/brand/${asset['id']}.png',
      _resize(_read(p.join(_kit, asset['src']! as String)), size),
    );
  }
  final logo = _read(p.join(_kit, 'logo/logo-full.png'));
  final splash = _read(p.join(_kit, 'logo/logo-clean.webp'));
  _png('assets/brand/logo.png', _resize(logo, 512));
  _android(logo, splash);
  _appleIcons('ios/Runner/Assets.xcassets/AppIcon.appiconset', logo);
  _appleIcons('macos/Runner/Assets.xcassets/AppIcon.appiconset', logo);
  for (final scale in [1, 2, 3]) {
    final suffix = scale == 1 ? '' : '@${scale}x';
    _png(
      'ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage$suffix.png',
      _resize(splash, 168 * scale),
    );
  }
  _write(
    'windows/runner/resources/app_icon.ico',
    img.encodeIco(_icon(logo, 256)),
  );
  stdout.writeln(
    'Prepared 19 runtime illustrations and Android/iOS/macOS/Windows branding.',
  );
}

img.Image _read(String path) =>
    img.decodeImage(File(path).readAsBytesSync())?.convert(numChannels: 4) ??
    (throw StateError('Cannot decode $path'));

img.Image _resize(img.Image source, int size) => img.copyResize(
  source,
  width: size,
  height: size,
  interpolation: img.Interpolation.cubic,
);

void _write(String relative, List<int> bytes) {
  final file = File(p.join(_root, relative));
  file.parent.createSync(recursive: true);
  file.writeAsBytesSync(bytes);
}

void _png(String relative, img.Image image) =>
    _write(relative, img.encodePng(image));

img.Image _icon(
  img.Image logo,
  int size, {
  bool transparent = false,
  double fraction = 1,
}) {
  final canvas = img.Image(
    width: size,
    height: size,
    numChannels: transparent ? 4 : 3,
  );
  if (!transparent) return _resize(logo, size).convert(numChannels: 3);
  return img.compositeImage(
    canvas,
    _resize(logo, (size * fraction).round()),
    center: true,
  );
}

// A soft version of the dog's blue ear keeps the white face readable.
void _fillIconBackground(img.Image canvas) {
  for (var y = 0; y < canvas.height; y++) {
    final progress = y / (canvas.height - 1);
    final red = (140 + (255 - 140) * progress).round();
    final green = (185 + (255 - 185) * progress).round();
    final blue = (238 + (255 - 238) * progress).round();
    for (var x = 0; x < canvas.width; x++) {
      canvas.setPixelRgb(x, y, red, green, blue);
    }
  }
}

void _android(img.Image logo, img.Image splash) {
  const res = 'android/app/src/main/res';
  for (final (density, size) in [
    ('mdpi', 48),
    ('hdpi', 72),
    ('xhdpi', 96),
    ('xxhdpi', 144),
    ('xxxhdpi', 192),
  ]) {
    _png('$res/mipmap-$density/ic_launcher.png', _icon(logo, size));
  }
  _png('$res/drawable-nodpi/brand_logo.png', _resize(splash, 512));
  _png(
    '$res/drawable-nodpi/brand_splash.png',
    _icon(splash, 432, transparent: true, fraction: 2 / 3),
  );
  final background = img.Image(width: 432, height: 432);
  _fillIconBackground(background);
  _png('$res/drawable-nodpi/ic_launcher_background.png', background);
  _png(
    '$res/drawable-nodpi/ic_launcher_foreground.png',
    _icon(logo, 432, transparent: true, fraction: 2 / 3),
  );
}

void _appleIcons(String relative, img.Image logo) {
  final contents = jsonDecode(
    File(p.join(_root, relative, 'Contents.json')).readAsStringSync(),
  ) as Map<String, Object?>;
  final seen = <String>{};
  for (final value in contents['images']! as List<Object?>) {
    final entry = value! as Map<String, Object?>;
    final name = entry['filename']! as String;
    if (!seen.add(name)) continue;
    final size = double.parse((entry['size']! as String).split('x').first);
    final scale = double.parse((entry['scale']! as String).replaceAll('x', ''));
    _png('$relative/$name', _icon(logo, (size * scale).round()));
  }
}
