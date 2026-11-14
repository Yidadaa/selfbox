import 'package:fpdart/fpdart.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/models/user_profile.dart';
import 'account_providers.dart';
import 'app_preferences_controller.dart';

part '../../../../gen/features/settings/presentation/providers/onboarding_controller.g.dart';

@riverpod
class OnboardingController extends _$OnboardingController {
  @override
  AsyncValue<Unit> build() {
    ref.watch(profileControllerProvider.notifier);
    return const AsyncData(unit);
  }

  Future<void> complete(UserProfile profile) async {
    if (state.isLoading) return;
    state = const AsyncLoading();
    final result = await ref
        .read(profileControllerProvider.notifier)
        .save(profile);
    if (!ref.mounted) return;
    final completed = await TaskEither.fromEither(result)
        .flatMap(
          (_) => TaskEither(
            ref
                .read(appPreferencesControllerProvider.notifier)
                .completeOnboarding,
          ),
        )
        .run();
    if (!ref.mounted) return;
    state = completed.match(
      (failure) => AsyncError(failure, StackTrace.current),
      (_) => const AsyncData(unit),
    );
  }
}
