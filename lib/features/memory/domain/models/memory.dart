import 'package:fpdart/fpdart.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/error/app_failure.dart';

part '../../../../gen/features/memory/domain/models/memory.freezed.dart';

/// A validated path inside the memory tree, e.g. `user/profile.md`.
///
/// Paths come straight from model tool calls, so this is the security
/// boundary: anything that could escape the memory root is rejected here.
extension type const MemoryPath._(String value) {
  static const maxLength = 160;
  static const maxDepth = 4;

  // Letters/digits in any script plus `-` and `_`; dots only for the suffix.
  static final _segment = RegExp(
    r'^[\p{L}\p{N}_-][\p{L}\p{N} _-]*$',
    unicode: true,
  );

  static Either<AppFailure, MemoryPath> parse(String raw) {
    AppFailure invalid(String why) =>
        AppFailure.validation(message: 'invalid memory path "$raw": $why');

    final path = raw.trim();
    if (path.isEmpty) return Left(invalid('empty'));
    if (path.length > maxLength) return Left(invalid('too long'));
    if (path.contains(r'\')) return Left(invalid('use "/" as separator'));
    if (path.startsWith('/')) return Left(invalid('must be relative'));
    if (!path.endsWith('.md')) return Left(invalid('must end with .md'));

    final segments = path.substring(0, path.length - 3).split('/');
    if (segments.length > maxDepth) {
      return Left(invalid('at most $maxDepth levels deep'));
    }
    for (final segment in segments) {
      if (segment.isEmpty || segment == '.' || segment == '..') {
        return Left(invalid('empty, "." or ".." segment'));
      }
      if (!_segment.hasMatch(segment)) {
        return Left(invalid('segment "$segment" has unsupported characters'));
      }
    }
    return Right(MemoryPath._(path));
  }

  List<String> get segments => value.split('/');

  /// Top-level folder, or empty for files at the root.
  String get folder => segments.length > 1 ? segments.first : '';

  String get fileName => segments.last;
}

@freezed
abstract class MemoryFile with _$MemoryFile {
  const factory MemoryFile({
    required MemoryPath path,
    required String content,
    required DateTime updatedAt,
  }) = _MemoryFile;
}

/// Listing entry without the body.
@freezed
abstract class MemoryEntry with _$MemoryEntry {
  const factory MemoryEntry({
    required MemoryPath path,
    required DateTime updatedAt,
    required int sizeBytes,

    /// First markdown heading, falling back to the file name.
    required String title,
  }) = _MemoryEntry;
}

@freezed
abstract class MemorySearchHit with _$MemorySearchHit {
  const factory MemorySearchHit({
    required MemoryPath path,
    required int line,
    required String text,
  }) = _MemorySearchHit;
}

/// Title shown for a memory file: its first `#` heading or the file name.
String memoryTitle(MemoryPath path, String content) {
  for (final line in content.split('\n')) {
    final trimmed = line.trim();
    if (trimmed.startsWith('#')) {
      final title = trimmed.replaceFirst(RegExp('^#+'), '').trim();
      if (title.isNotEmpty) return title;
    }
  }
  final name = path.fileName;
  return name.substring(0, name.length - 3);
}
