import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/memory/data/memory_data_providers.dart';
import '../../features/memory/domain/services/user_memory_service.dart';

part '../../gen/core/storage/user_memory_provider.g.dart';

@riverpod
UserMemoryService userMemoryService(Ref ref) =>
    UserMemoryService(ref.watch(memoryRepositoryProvider));
