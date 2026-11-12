import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'features/chat/data/chat_data_providers.dart';
import 'features/settings/data/repositories/sdk_model_probe.dart';
import 'features/settings/data/settings_data_providers.dart';
import 'features/settings/domain/repositories/model_probe.dart';
import 'features/settings/domain/services/model_test_service.dart';

part 'gen/model_test_providers.g.dart';

@riverpod
ModelProbe modelProbe(Ref ref) =>
    SdkModelProbe(ref.watch(languageModelFactoryProvider));

@riverpod
ModelTestService modelTestService(Ref ref) => ModelTestService(
  ref.watch(aiSettingsRepositoryProvider),
  ref.watch(modelProbeProvider),
);
