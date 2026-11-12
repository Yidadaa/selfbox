import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:selfbox/core/error/app_failure.dart';
import 'package:selfbox/core/testing/app_widget_tester.dart';
import 'package:selfbox/core/testing/fake_account_repository.dart';
import 'package:selfbox/features/settings/domain/models/user_profile.dart';
import 'package:selfbox/features/settings/presentation/providers/account_providers.dart';

void main() {
  test('profile save refreshes public profile state', () async {
    final account = FakeAccountRepository();
    final container = ProviderContainer(
      overrides: testAppOverrides(account: account),
    );
    addTearDown(container.dispose);
    final sub = container.listen(profileControllerProvider, (_, next) {});
    addTearDown(sub.close);
    await container.read(userProfileProvider.future);
    expect(
      (await container
              .read(profileControllerProvider.notifier)
              .save(const UserProfile(nickname: 'Flynn')))
          .isRight(),
      true,
    );
    expect(
      (await container.read(userProfileProvider.future)).nickname,
      'Flynn',
    );
    expect(container.read(profileControllerProvider), false);
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
