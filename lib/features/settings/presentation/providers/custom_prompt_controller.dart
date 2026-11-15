import 'package:fpdart/fpdart.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/error/app_failure.dart';
import 'settings_providers.dart';

part '../../../../gen/features/settings/presentation/providers/custom_prompt_controller.g.dart';

@riverpod
class CustomPromptController extends _$CustomPromptController {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<Either<AppFailure, Unit>> save(String prompt) async {
    if (state.isLoading) {
      return const Left(
        AppFailure.validation(message: 'Save already in progress'),
      );
    }
    state = const AsyncLoading();
    final result = await ref
        .read(aiSettingsServiceProvider)
        .setCustomPrompt(prompt)
        .run();
    if (ref.mounted) {
      state = result.match(
        (failure) => AsyncError(failure, StackTrace.current),
        (_) => const AsyncData(null),
      );
    }
    return result.map((_) => unit);
  }
}
