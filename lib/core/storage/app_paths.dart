import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:riverpod_annotation/riverpod_annotation.dart';

part '../../gen/core/storage/app_paths.g.dart';

/// Sandboxed on-device directories. Everything the app persists lives under
/// [root], so tests can point the whole app at a temp directory.
class AppPaths {
  const AppPaths(this.root);

  final Directory root;

  Directory get database => Directory(p.join(root.path, 'objectbox'));

  /// Images attached to messages; referenced by path relative to [root].
  Directory get media => Directory(p.join(root.path, 'media'));

  /// The agent's markdown memory tree.
  Directory get memory => Directory(p.join(root.path, 'memory'));
}

/// Overridden in `main()` with the platform documents directory.
@Riverpod(keepAlive: true)
AppPaths appPaths(Ref ref) =>
    throw StateError('appPathsProvider must be overridden at startup');
