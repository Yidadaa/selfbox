import 'package:flutter/painting.dart';
import 'package:fpdart/fpdart.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/chat/data/chat_data_providers.dart';
import '../../features/chat/presentation/providers/assistant_controller.dart';
import '../../features/chat/presentation/providers/composer_controller.dart';
import '../../features/memory/data/memory_data_providers.dart';
import '../../features/settings/data/settings_data_providers.dart';
import '../../features/settings/domain/services/clear_app_data.dart';
import '../../features/settings/presentation/providers/account_providers.dart';
import '../../features/settings/presentation/providers/settings_providers.dart';
import '../error/app_failure.dart';

part '../../gen/core/storage/data_reset_controller.g.dart';

/// Composition boundary: stop producers before removing their persisted data.
@Riverpod(keepAlive: true)
class DataResetController extends _$DataResetController {
  @override
  bool build() => false;

  Future<Either<AppFailure, Unit>> clear() async {
    if (state) return const Right(unit);
    state = true;
    final composer = ref.read(composerControllerProvider.notifier);
    await composer.finishPending();
    await ref.read(assistantControllerProvider.notifier).cancelAndWait();
    await ref.read(aiSettingsServiceProvider).finishPending();
    composer.resetDraft();
    final result = await ClearAppData(
      ref.read(aiSettingsRepositoryProvider),
      ref.read(messageRepositoryProvider),
      ref.read(memoryRepositoryProvider),
      ref.read(accountRepositoryProvider),
    ).run().run();
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
    ref.invalidate(userProfileProvider);
    ref.invalidate(storageUsageProvider);
    state = false;
    return result;
  }
}
