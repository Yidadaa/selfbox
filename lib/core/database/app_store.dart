import 'package:objectbox/objectbox.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

// `show` keeps Store resolvable from the package import: riverpod_generator
// runs before objectbox.g.dart exists and cannot see types re-exported by it.
import '../../gen/database/objectbox.g.dart' show openStore;
import '../storage/app_paths.dart';

part '../../gen/core/database/app_store.g.dart';

/// Opens the single ObjectBox store under the app's sandboxed directory.
Future<Store> openAppStore(AppPaths paths) async {
  await paths.database.create(recursive: true);
  return openStore(directory: paths.database.path);
}

/// Overridden in `main()` with the store returned by [openAppStore]; opening
/// is async and must finish before the first frame reads any repository.
@Riverpod(keepAlive: true)
Store appStore(Ref ref) =>
    throw StateError('appStoreProvider must be overridden at startup');
