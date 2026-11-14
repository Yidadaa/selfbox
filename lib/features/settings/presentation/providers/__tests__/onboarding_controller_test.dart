import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:selfbox/core/error/app_failure.dart';
import 'package:selfbox/core/testing/app_widget_tester.dart';
import 'package:selfbox/core/testing/fake_account_repository.dart';
import 'package:selfbox/core/testing/fake_app_preferences_repository.dart';
import 'package:selfbox/core/testing/fake_memory_repository.dart';
import 'package:selfbox/features/memory/domain/models/memory.dart';
import 'package:selfbox/features/settings/domain/models/user_profile.dart';
import 'package:selfbox/features/settings/presentation/providers/app_preferences_controller.dart';
import 'package:selfbox/features/settings/presentation/providers/onboarding_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  for (final failAt in ['profile', 'memory', 'preferences']) {
    test(
      'completion waits for $failAt persistence and supports retry',
      () async {
        final account = FakeAccountRepository();
        final preferences = FakeAppPreferencesRepository();
        final memory = _FailingMemory();
        const failure = AppFailure.database(message: 'full');
        if (failAt == 'profile') account.saveFailure = failure;
        if (failAt == 'memory') memory.failure = failure;
        if (failAt == 'preferences') preferences.failure = failure;
        final container = ProviderContainer(
          overrides: testAppOverrides(
            account: account,
            preferences: preferences,
            memory: memory,
          ),
        );
        addTearDown(container.dispose);
        final sub = container.listen(onboardingControllerProvider, (_, _) {});
        addTearDown(sub.close);
        const profile = UserProfile(
          agentName: 'Momo',
          nickname: 'Flynn',
          agentAvatar: 'preset:reading',
        );
        final controller = container.read(
          onboardingControllerProvider.notifier,
        );
        await controller.complete(profile);
        expect(container.read(onboardingControllerProvider).error, failure);
        expect(
          container.read(appPreferencesControllerProvider).onboardingCompleted,
          isFalse,
        );
        account.saveFailure = null;
        memory.failure = null;
        preferences.failure = null;
        await controller.complete(profile);
        expect(container.read(onboardingControllerProvider).hasError, isFalse);
        expect(account.profile, profile);
        expect(memory.contentOf('user.md'), contains('用户已经设置了名字'));
        expect(preferences.current.onboardingCompleted, isTrue);
      },
    );
  }
  test('a pending save blocks duplicate completion', () async {
    final account = _DelayedAccount();
    final preferences = FakeAppPreferencesRepository();
    final container = ProviderContainer(
      overrides: testAppOverrides(account: account, preferences: preferences),
    );
    addTearDown(container.dispose);
    final sub = container.listen(onboardingControllerProvider, (_, _) {});
    addTearDown(sub.close);
    final controller = container.read(onboardingControllerProvider.notifier);
    final saving = controller.complete(const UserProfile());
    await controller.complete(const UserProfile());
    expect(account.saves, 1);
    expect(container.read(onboardingControllerProvider).isLoading, isTrue);
    expect(preferences.current.onboardingCompleted, isFalse);
    account.pending.complete(const Right(unit));
    await saving;
    expect(preferences.current.onboardingCompleted, isTrue);
  });
}

class _FailingMemory extends FakeMemoryRepository {
  AppFailure? failure;
  @override
  TaskEither<AppFailure, Option<MemoryFile>> read(MemoryPath path) =>
      switch (failure) {
        final AppFailure failure => TaskEither.left(failure),
        null => super.read(path),
      };
}

class _DelayedAccount extends FakeAccountRepository {
  final pending = Completer<Either<AppFailure, Unit>>();
  int saves = 0;
  @override
  TaskEither<AppFailure, Unit> save(UserProfile value) {
    saves++;
    return TaskEither(() => pending.future);
  }
}
