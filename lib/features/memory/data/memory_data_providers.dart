import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/storage/app_paths.dart';
import '../domain/repositories/memory_repository.dart';
import 'repositories/file_memory_repository.dart';

part '../../../gen/features/memory/data/memory_data_providers.g.dart';

@Riverpod(keepAlive: true)
MemoryRepository memoryRepository(Ref ref) =>
    FileMemoryRepository(ref.watch(appPathsProvider).memory);
