import 'dart:io';
import 'dart:typed_data';

import 'package:fpdart/fpdart.dart';
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

  TaskEither<AppFailure, String> saveImage(
    Uint8List bytes, {
    required String extension,
  }) => TaskEither.tryCatch(() async {
    final ext = extension.replaceAll('.', '').toLowerCase();
    final relative = '$_folder/${_uuid.v4()}.${ext.isEmpty ? 'jpg' : ext}';
    final file = File(p.join(_paths.root.path, relative));
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes, flush: true);
    return relative;
  }, (error, _) => AppFailure.unexpected(error: error));

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
          return unit;
        }, (error, _) => AppFailure.unexpected(error: error)),
      );
}
