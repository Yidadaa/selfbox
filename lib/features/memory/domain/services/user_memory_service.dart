import 'package:fpdart/fpdart.dart';

import '../../../../core/error/app_failure.dart';
import '../models/memory.dart';
import '../repositories/memory_repository.dart';

/// Keeps the starter profile hint in sync without replacing personal notes.
class UserMemoryService {
  const UserMemoryService(this.memory);

  final MemoryRepository memory;

  static const _unnamed = '用户尚未设置名字，可以引导用户点击头像设置名字和头像。';
  static const _named = '用户已经设置了名字，请优先用用户的名字称呼他。';
  static final path = MemoryPath.parse('user.md')
      .getOrElse((failure) => throw failure);

  TaskEither<AppFailure, Unit> ensure(String nickname) => memory
      .read(path)
      .flatMap(
        (file) => switch (file) {
          None() => memory.create(path, _line(nickname)).map((_) => unit),
          Some(value: final current) => _update(current, nickname),
        },
      );

  TaskEither<AppFailure, Unit> _update(MemoryFile file, String nickname) {
    final lines = file.content.split('\n');
    final previous = lines.first;
    if (previous != _unnamed && previous != _named) {
      return TaskEither.right(unit);
    }
    final next = _line(nickname);
    if (previous == next) return TaskEither.right(unit);
    lines[0] = next;
    return memory
        .replace(path, lines.join('\n'), expectedContent: file.content)
        .map((_) => unit);
  }

  static String _line(String nickname) =>
      nickname.trim().isEmpty ? _unnamed : _named;
}
