import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:fpdart/fpdart.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import '../../../../core/error/app_failure.dart';
import '../../../../core/storage/app_paths.dart';

/// Stores message images under `media/` and hands out root-relative paths,
/// so the database never holds absolute paths that break on reinstall.
class MediaStore {
  MediaStore(this._paths);

  final AppPaths _paths;
  static const _uuid = Uuid();

  static const _folder = 'media';
  static const _maxImageSide = 2048;
  static const _thumbnailSide = 320;
  static const _imageQuality = 85;
  static const _thumbnailQuality = 70;

  TaskEither<AppFailure, String> saveImage(Uint8List bytes) =>
      TaskEither.tryCatch(() async {
        final optimized = await Isolate.run(() => _optimizeImage(bytes));
        final relative = '$_folder/${_uuid.v4()}.jpg';
        final file = File(p.join(_paths.root.path, relative));
        final thumbnail = File('${p.withoutExtension(file.path)}.thumb.jpg');
        final fullTemp = File('${file.path}.tmp');
        final thumbnailTemp = File('${thumbnail.path}.tmp');
        await file.parent.create(recursive: true);
        try {
          await fullTemp.writeAsBytes(optimized.full, flush: true);
          await thumbnailTemp.writeAsBytes(optimized.thumbnail, flush: true);
          await fullTemp.rename(file.path);
          await thumbnailTemp.rename(thumbnail.path);
        } catch (_) {
          await _removeIfPresent(file);
          await _removeIfPresent(thumbnail);
          rethrow;
        } finally {
          await _removeIfPresent(fullTemp);
          await _removeIfPresent(thumbnailTemp);
        }
        return relative;
      }, _saveFailure);

  /// The file for a stored relative path; `none` for anything that escapes
  /// the media folder (the path may come from the model's tool arguments).
  Option<File> resolve(String relative) {
    final normalized = p.posix.normalize(relative.replaceAll(r'\', '/'));
    final escapes =
        p.posix.isAbsolute(normalized) ||
        !p.posix.isWithin(_folder, normalized);
    if (escapes) return const None();
    // Native separators: the same file must map to the same path string,
    // since image caches key on it.
    return Some(
      File(p.joinAll([_paths.root.path, ...p.posix.split(normalized)])),
    );
  }

  /// Returns the sidecar thumbnail for a valid media path.
  Option<File> thumbnail(String relative) =>
      resolve(relative)
          .map((file) => File('${p.withoutExtension(file.path)}.thumb.jpg'));

  TaskEither<AppFailure, Uint8List> read(String relative) =>
      resolve(relative).match(
        () => TaskEither.left(
          AppFailure.validation(message: 'invalid media path: $relative'),
        ),
        (file) => TaskEither.tryCatch(
          file.readAsBytes,
          (error, _) =>
              AppFailure.database(message: 'missing media: $relative'),
        ),
      );

  TaskEither<AppFailure, Unit> delete(String relative) =>
      resolve(relative).match(
        () => TaskEither.right(unit),
        (file) => TaskEither.tryCatch(() async {
          if (await file.exists()) await file.delete();
          final thumb = File('${p.withoutExtension(file.path)}.thumb.jpg');
          if (await thumb.exists()) await thumb.delete();
          return unit;
        }, (error, _) => AppFailure.unexpected(error: error)),
      );

  static AppFailure _saveFailure(Object error, StackTrace stackTrace) =>
      switch (error) {
        FormatException() => const AppFailure.validation(
          message: 'unsupported image',
        ),
        _ => AppFailure.unexpected(error: error, stackTrace: stackTrace),
      };
}

Future<void> _removeIfPresent(File file) async {
  if (await file.exists()) await file.delete();
}

({Uint8List full, Uint8List thumbnail}) _optimizeImage(Uint8List bytes) {
  final decoded = img.decodeImage(bytes);
  if (decoded == null) {
    throw const FormatException('unsupported image');
  }
  final oriented = img.bakeOrientation(decoded);
  final full = _resizeToBound(oriented, MediaStore._maxImageSide);
  final thumbnail = _resizeToBound(full, MediaStore._thumbnailSide);
  return (
    full: Uint8List.fromList(
      img.encodeJpg(full, quality: MediaStore._imageQuality),
    ),
    thumbnail: Uint8List.fromList(
      img.encodeJpg(thumbnail, quality: MediaStore._thumbnailQuality),
    ),
  );
}

img.Image _resizeToBound(img.Image source, int maxSide) {
  if (source.width <= maxSide && source.height <= maxSide) {
    return source;
  }
  final scale =
      maxSide / (source.width > source.height ? source.width : source.height);
  return img.copyResize(
    source,
    width: (source.width * scale).round(),
    height: (source.height * scale).round(),
  );
}
