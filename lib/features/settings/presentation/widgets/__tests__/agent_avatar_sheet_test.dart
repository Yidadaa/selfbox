import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:selfbox/core/router/app_router.dart';
import 'package:selfbox/core/testing/app_widget_tester.dart';
import 'package:selfbox/core/testing/fake_account_repository.dart';
import 'package:selfbox/features/settings/domain/models/agent_avatar.dart';
import 'package:selfbox/features/settings/domain/models/user_profile.dart';
import 'package:selfbox/features/settings/presentation/providers/account_providers.dart';
import 'package:selfbox/features/settings/presentation/widgets/agent_avatar_sheet.dart';
import 'package:selfbox/gen/i18n/strings.g.dart';

void main() {
  testWidgets('gallery selection becomes the Agent avatar only after saving', (
    tester,
  ) async {
    final picker = _Picker(denied: false, choosePhoto: true);
    final account = FakeAccountRepository();
    final container = await tester.pumpApp(
      account: account,
      overrides: [avatarPickerProvider.overrideWithValue(picker)],
    );
    container.read(appRouterProvider).go('/me/profile');
    await tester.pumpAndSettle();
    await tester.tap(find.text(t.me.changeAvatar));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('avatar-gallery')));
    await tester.pumpAndSettle();
    expect(picker.calls, 1);
    expect(find.byType(AgentAvatarSheet), findsNothing);
    expect(account.profile.agentAvatar, isNull);
    await tester.tap(find.text(t.common.save));
    await tester.pumpAndSettle();
    expect(account.profile.agentAvatar, 'media/avatar-test.png');
  });
  for (final denied in [false, true]) {
    testWidgets('gallery requires explicit tap and handles denied=$denied', (
      tester,
    ) async {
      final picker = _Picker(denied: denied);
      final account = FakeAccountRepository()
        ..profile = const UserProfile(agentAvatar: 'preset:playing');
      final container = await tester.pumpApp(
        account: account,
        overrides: [avatarPickerProvider.overrideWithValue(picker)],
      );
      container.read(appRouterProvider).go('/me/profile');
      await tester.pumpAndSettle();
      await tester.tap(find.text(t.me.changeAvatar));
      await tester.pumpAndSettle();
      expect(picker.calls, 0);
      await tester.tap(find.byKey(const ValueKey('avatar-gallery')));
      await tester.pumpAndSettle();
      expect(picker.calls, 1);
      expect(find.byType(AgentAvatarSheet), findsOneWidget);
      expect(account.profile.agentAvatar, 'preset:playing');
      if (denied) {
        expect(find.text(t.settings.errors.generic), findsOneWidget);
        await tester.pump(const Duration(seconds: 4));
        await tester.pumpAndSettle();
      }
      await tester.tap(find.byTooltip(t.common.close));
      await tester.pumpAndSettle();
      expect(account.profile.agentAvatar, 'preset:playing');
    });
  }
  for (final brightness in Brightness.values) {
    testWidgets(
      'all presets and final gallery fit narrow large-text sheet in $brightness',
      (tester) async {
        await tester.pumpPage(const AgentAvatarSheet(), brightness: brightness);
        tester.view.physicalSize = const Size(280 * 3, 600 * 3);
        tester.platformDispatcher.textScaleFactorTestValue = 1.8;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        await tester.pumpAndSettle();
        for (final preset in AgentAvatarPreset.values) {
          final tile = find.byKey(ValueKey('avatar-preset-${preset.name}'));
          expect(tile, findsOneWidget);
          final rect = tester.getRect(tile);
          expect(rect.width, greaterThanOrEqualTo(48));
          expect(rect.left, greaterThanOrEqualTo(0));
          expect(rect.right, lessThanOrEqualTo(280));
        }
        final gallery = find.byKey(const ValueKey('avatar-gallery'));
        await tester.ensureVisible(gallery);
        await tester.pumpAndSettle();
        expect(tester.getRect(gallery).bottom, lessThanOrEqualTo(600));
        expect(tester.takeException(), isNull);
      },
    );
  }
}

class _Picker extends Fake implements ImagePicker {
  _Picker({required this.denied, this.choosePhoto = false});
  final bool denied;
  final bool choosePhoto;
  int calls = 0;
  @override
  Future<XFile?> pickImage({
    required ImageSource source,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
    bool requestFullMetadata = true,
  }) async {
    calls++;
    expect(source, ImageSource.gallery);
    if (denied) throw PlatformException(code: 'photo_access_denied');
    if (choosePhoto) {
      return XFile.fromData(Uint8List.fromList([1, 2, 3]), name: 'photo.png');
    }
    return null;
  }
}
