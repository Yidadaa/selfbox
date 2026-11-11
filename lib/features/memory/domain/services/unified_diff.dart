import 'package:fpdart/fpdart.dart';

import '../../../../core/error/app_failure.dart';

/// Applies a unified diff (as produced by `diff -u` / `git diff`) to [original].
///
/// The agent edits memory files only through this, so a patch must prove it
/// was written against the current content: every context and removed line
/// has to match exactly. Hunk line numbers are treated as hints — hunks are
/// located by content, searching outward from the hinted line, so a model
/// that miscounts lines still applies cleanly as long as its context is right.
/// Hunks without numbers (`@@ @@`) are accepted.
Either<AppFailure, String> applyUnifiedDiff(String original, String patch) {
  final hunks = _parseHunks(patch);
  if (hunks.isLeft()) return hunks.map((_) => original);
  final parsed = hunks.getOrElse((_) => const []);
  if (parsed.isEmpty) {
    return const Left(AppFailure.validation(message: 'patch has no hunks'));
  }

  final usesCrlf = original.contains('\r\n');
  final normalized = original.replaceAll('\r\n', '\n');
  final hadTrailingNewline = normalized.isEmpty || normalized.endsWith('\n');
  final lines = normalized.isEmpty
      ? <String>[]
      : (hadTrailingNewline
                ? normalized.substring(0, normalized.length - 1)
                : normalized)
            .split('\n');

  // `cursor` keeps hunks in order and stops two hunks claiming the same lines.
  var cursor = 0;
  final out = <String>[];
  for (final (index, hunk) in parsed.indexed) {
    final at = _locate(lines, hunk, from: cursor);
    if (at == null) {
      return Left(
        AppFailure.validation(
          message:
              'hunk ${index + 1} does not match the file; '
              're-read the file and resend the patch with exact context. '
              'Expected:\n${hunk.before.join('\n')}',
        ),
      );
    }
    out
      ..addAll(lines.sublist(cursor, at))
      ..addAll(hunk.after);
    cursor = at + hunk.before.length;
  }
  out.addAll(lines.sublist(cursor));

  final text = out.isEmpty ? '' : '${out.join('\n')}\n';
  return Right(usesCrlf ? text.replaceAll('\n', '\r\n') : text);
}

class _Hunk {
  _Hunk(this.hintLine);

  /// Zero-based start line from the header, if it had one.
  final int? hintLine;
  final before = <String>[];
  final after = <String>[];
}

final _header = RegExp(r'^@@ -(\d+)(?:,\d+)? \+\d+(?:,\d+)? @@');

Either<AppFailure, List<_Hunk>> _parseHunks(String patch) {
  final hunks = <_Hunk>[];
  _Hunk? current;
  for (final raw in patch.replaceAll('\r\n', '\n').split('\n')) {
    if (raw.startsWith('---') || raw.startsWith('+++')) continue;
    if (raw.startsWith('@@')) {
      final match = _header.firstMatch(raw);
      final start = match == null ? null : int.parse(match.group(1)!);
      current = _Hunk(start == null ? null : (start == 0 ? 0 : start - 1));
      hunks.add(current);
      continue;
    }
    if (raw.startsWith(r'\ No newline')) continue;
    final hunk = current;
    if (hunk == null) {
      if (raw.trim().isEmpty) continue;
      return Left(
        AppFailure.validation(
          message: 'patch text before the first @@: "$raw"',
        ),
      );
    }
    if (raw.isEmpty) {
      // Editors often strip the single space of an empty context line.
      hunk.before.add('');
      hunk.after.add('');
      continue;
    }
    final body = raw.substring(1);
    switch (raw[0]) {
      case ' ':
        hunk.before.add(body);
        hunk.after.add(body);
      case '-':
        hunk.before.add(body);
      case '+':
        hunk.after.add(body);
      default:
        return Left(
          AppFailure.validation(
            message:
                'invalid patch line (must start with " ", "+" or "-"): "$raw"',
          ),
        );
    }
  }
  // A trailing newline in the patch text yields one phantom empty context
  // line at the very end; it never matches anything real, so drop it.
  for (final hunk in hunks) {
    while (hunk.before.isNotEmpty &&
        hunk.after.isNotEmpty &&
        hunk.before.last.isEmpty &&
        hunk.after.last.isEmpty) {
      hunk.before.removeLast();
      hunk.after.removeLast();
    }
  }
  return Right(hunks);
}

/// The start index where [hunk.before] matches [lines], at or after [from],
/// preferring the position closest to the header's hint.
int? _locate(List<String> lines, _Hunk hunk, {required int from}) {
  final before = hunk.before;
  if (before.isEmpty) {
    // Pure insertion: trust the hint, else append at the cursor.
    final hint = hunk.hintLine;
    return hint == null ? from : hint.clamp(from, lines.length);
  }
  bool matchesAt(int start) {
    if (start < from || start + before.length > lines.length) return false;
    for (var i = 0; i < before.length; i++) {
      if (lines[start + i] != before[i]) return false;
    }
    return true;
  }

  final hint = (hunk.hintLine ?? from).clamp(from, lines.length);
  for (var distance = 0; distance <= lines.length; distance++) {
    if (matchesAt(hint + distance)) return hint + distance;
    if (distance > 0 && matchesAt(hint - distance)) return hint - distance;
  }
  return null;
}
