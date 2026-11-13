import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

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
  final logo = _removeSpecks(_read(p.join(_kit, 'logo/logo-clean.webp')));
  _png('assets/brand/logo.png', _resize(logo, 512));
  _android(logo);
  _appleIcons('ios/Runner/Assets.xcassets/AppIcon.appiconset', logo);
  _appleIcons('macos/Runner/Assets.xcassets/AppIcon.appiconset', logo);
  for (final scale in [1, 2, 3]) {
    final suffix = scale == 1 ? '' : '@${scale}x';
    _png(
      'ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage$suffix.png',
      _resize(logo, 168 * scale),
    );
  }
  _write(
    'windows/runner/resources/app_icon.ico',
    img.encodeIco(_resize(logo, 256)),
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
  double fraction = 0.8,
}) {
  final canvas = img.Image(
    width: size,
    height: size,
    numChannels: transparent ? 4 : 3,
  );
  if (!transparent) img.fill(canvas, color: img.ColorRgb8(242, 246, 252));
  return img.compositeImage(
    canvas,
    _resize(logo, (size * fraction).round()),
    center: true,
  );
}

void _android(img.Image logo) {
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
  _png('$res/drawable-nodpi/brand_logo.png', _resize(logo, 512));
  _png(
    '$res/drawable-nodpi/ic_launcher_foreground.png',
    _icon(logo, 432, transparent: true, fraction: 0.62),
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

// The supplied WebP contains disconnected edge flecks. Keep the dog and star,
// removing only tiny alpha islands before downsampling the native brand mark.
img.Image _removeSpecks(img.Image image) {
  final visited = Uint8List(image.width * image.height);
  final queue = Int32List(visited.length);
  for (var start = 0; start < visited.length; start++) {
    if (visited[start] != 0) continue;
    visited[start] = 1;
    if (image.getPixel(start % image.width, start ~/ image.width).a < 20) {
      continue;
    }
    var count = 1;
    queue[0] = start;
    for (var head = 0; head < count; head++) {
      final index = queue[head];
      final x = index % image.width;
      final y = index ~/ image.width;
      for (final next in [
        if (x > 0) index - 1,
        if (x + 1 < image.width) index + 1,
        if (y > 0) index - image.width,
        if (y + 1 < image.height) index + image.width,
      ]) {
        if (visited[next] != 0) continue;
        visited[next] = 1;
        if (image.getPixel(next % image.width, next ~/ image.width).a >= 20) {
          queue[count++] = next;
        }
      }
    }
    if (count >= 160) continue;
    for (var i = 0; i < count; i++) {
      image.getPixel(queue[i] % image.width, queue[i] ~/ image.width).a = 0;
    }
  }
  return image;
}
