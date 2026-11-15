import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:selfbox/core/error/app_failure.dart';
import 'package:selfbox/features/settings/domain/models/ai_settings.dart';
import 'package:selfbox/features/settings/domain/models/user_profile.dart';
import 'package:selfbox/features/settings/presentation/providers/account_providers.dart';
import 'package:selfbox/features/settings/presentation/providers/settings_providers.dart';
import 'package:selfbox/main.dart' show appRiverpodObserver;
import 'package:talker_flutter/talker_flutter.dart';

import '../../../../support/app_widget_tester.dart';
import '../../../../support/fake_account_repository.dart';
import '../../../../support/fake_ai_settings.dart';
import '../../../../support/fake_memory_repository.dart';

void main() {
  test('profile save refreshes public profile state', () async {
    final account = FakeAccountRepository();
    final memory = FakeMemoryRepository();
    final container = ProviderContainer(
      overrides: testAppOverrides(account: account, memory: memory),
    );
    addTearDown(container.dispose);
    final sub = container.listen(profileControllerProvider, (_, next) {});
    addTearDown(sub.close);
    await container.read(userProfileProvider.future);
    expect(
      (await container
              .read(profileControllerProvider.notifier)
              .save(
                const UserProfile(
                  nickname: 'Flynn',
                  agentName: 'Dozy',
                  agentAvatar: 'preset:reading',
                ),
              ))
          .isRight(),
      true,
    );
    expect(
      (await container.read(userProfileProvider.future)).nickname,
      'Flynn',
    );
    expect(container.read(profileControllerProvider), false);
    expect(memory.contentOf('user.md'), contains('用户已经设置了名字'));
    expect(memory.contentOf('user.md'), isNot(contains('Dozy')));
    expect(
      (await container.read(userProfileProvider.future)).agentName,
      'Dozy',
    );
  });

  for (final denied in [false, true]) {
    test(
      'avatar picker handles ${denied ? 'permission denial' : 'cancellation'}',
      () async {
        final container = ProviderContainer(
          overrides: [
            ...testAppOverrides(),
            avatarPickerProvider.overrideWithValue(_Picker(denied)),
          ],
        );
        addTearDown(container.dispose);
        final sub = container.listen(profileControllerProvider, (_, next) {});
        addTearDown(sub.close);
        final result = await container
            .read(profileControllerProvider.notifier)
            .pickAvatar();
        if (denied) {
          expect(result.getLeft().toNullable(), isA<PermissionFailure>());
        } else {
          expect(result.isRight(), true);
          expect(result.getOrElse((e) => throw e), isNull);
        }
        expect(container.read(profileControllerProvider), false);
      },
    );
  }
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

class _Picker extends Fake implements ImagePicker {
  _Picker(this.denied);
  final bool denied;
  @override
  Future<XFile?> pickImage({
    required ImageSource source,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
    bool requestFullMetadata = true,
  }) async {
    if (denied) throw PlatformException(code: 'photo_access_denied');
    return null;
  }
}

class _SlowSettings extends FakeAiSettingsRepository {
  Completer<Either<AppFailure, Unit>> result = Completer();
  @override
  TaskEither<AppFailure, Unit> save(AiSettings settings) =>
      TaskEither(() => result.future);
}
