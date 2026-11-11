import 'dart:io';

/// Downloads the ObjectBox C library matching `objectbox_flutter_libs` into
/// the project root so `flutter test` can open a real Store on the host.
///
///   dart run tool/fetch_objectbox_native.dart
///
/// The file is gitignored; app builds bundle their own copy via
/// objectbox_flutter_libs.
const _version = '6.0.0-beta2';

Future<void> main() async {
  final (asset, libName) = switch (Platform.operatingSystem) {
    'windows' => ('objectbox-windows-x64.zip', 'objectbox.dll'),
    'linux' => ('objectbox-linux-x64.tar.gz', 'libobjectbox.so'),
    'macos' => ('objectbox-macos-universal.zip', 'libobjectbox.dylib'),
    final os => throw UnsupportedError('No ObjectBox host library for $os'),
  };
  if (File(libName).existsSync()) {
    stdout.writeln('$libName already present');
    return;
  }

  final temp = Directory.systemTemp.createTempSync('objectbox_native_');
  try {
    final archive = File('${temp.path}/$asset');
    final url = Uri.parse(
      'https://github.com/objectbox/objectbox-c/releases/download/v$_version/$asset',
    );
    stdout.writeln('Downloading $url');
    final client = HttpClient();
    final response = await (await client.getUrl(url)).close();
    if (response.statusCode != HttpStatus.ok) {
      throw HttpException('HTTP ${response.statusCode}', uri: url);
    }
    await response.pipe(archive.openWrite());
    client.close();

    final extract = Process.runSync('tar', [
      '-xf',
      archive.path,
      '-C',
      temp.path,
    ]);
    if (extract.exitCode != 0) {
      throw ProcessException('tar', [], '${extract.stderr}');
    }

    File('${temp.path}/lib/$libName').copySync(libName);
    stdout.writeln('Installed $libName');
  } finally {
    temp.deleteSync(recursive: true);
  }
}
