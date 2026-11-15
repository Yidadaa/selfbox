import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:selfbox/core/error/app_failure.dart';
import 'package:selfbox/core/testing/app_widget_tester.dart';
import 'package:selfbox/core/testing/fake_ai_settings.dart';
import 'package:selfbox/features/settings/domain/models/ai_settings.dart';
import 'package:selfbox/features/settings/domain/models/user_profile.dart';
import 'package:selfbox/features/settings/presentation/providers/account_providers.dart';
import 'package:selfbox/features/settings/presentation/providers/settings_providers.dart';
import 'package:selfbox/main.dart' show appRiverpodObserver;
import 'package:talker_flutter/talker_flutter.dart';

void main() {
  test('custom instructions do not enter provider logs', () async {
    final talker = Talker(settings: TalkerSettings(useConsoleLogs: false));
    final container = ProviderContainer(
      overrides: testAppOverrides(
        settings: FakeAiSettingsRepository(
          settings: const AiSettings(
            customPrompt: 'private-custom-instructions',
          ),
        ),
      ),
      observers: [appRiverpodObserver(talker)],
    );
    addTearDown(container.dispose);
    final subscription = container.listen(aiSettingsProvider, (_, _) {});
    addTearDown(subscription.close);
    await container.read(aiSettingsProvider.future);
    expect(
      talker.history.map((entry) => entry.generateTextMessage()).join(),
      isNot(contains('private-custom-instructions')),
    );
  });
  test(
    'save publishes loading, prevents duplicates and recovers from failure',
    () async {
      final repo = _SlowSettings();
      final container = ProviderContainer(
        overrides: testAppOverrides(settings: repo),
      );
      addTearDown(container.dispose);
      final seen = <bool>[];
      final sub = container.listen(
        profileControllerProvider,
        (_, next) => seen.add(next),
      );
      addTearDown(sub.close);
      final controller = container.read(profileControllerProvider.notifier);
      final saving = controller.save(
        const UserProfile(),
        customPrompt: 'Hello',
      );
      expect(container.read(profileControllerProvider), isTrue);
      expect(
        (await controller.save(
          const UserProfile(),
          customPrompt: 'Duplicate',
        )).isLeft(),
        isTrue,
      );
      repo.result.complete(const Left(AppFailure.database(message: 'disk')));
      expect((await saving).isLeft(), isTrue);
      expect(container.read(profileControllerProvider), isFalse);
      repo.result = Completer()..complete(const Right(unit));
      expect(
        (await controller.save(
          const UserProfile(),
          customPrompt: 'Retry',
        )).isRight(),
        isTrue,
      );
      expect(seen, [true, false, true, false]);
    },
  );
}

class _SlowSettings extends FakeAiSettingsRepository {
  Completer<Either<AppFailure, Unit>> result = Completer();
  @override
  TaskEither<AppFailure, Unit> save(AiSettings settings) =>
      TaskEither(() => result.future);
}
