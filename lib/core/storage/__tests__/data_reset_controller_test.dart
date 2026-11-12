import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:selfbox/core/error/app_failure.dart';
import 'package:selfbox/core/storage/data_reset_controller.dart';
import 'package:selfbox/core/testing/app_widget_tester.dart';
import 'package:selfbox/core/testing/fake_account_repository.dart';
import 'package:selfbox/core/testing/fake_memory_repository.dart';
import 'package:selfbox/features/chat/presentation/providers/composer_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('reset waits for pending selection, prevents duplicate reset, and clears draft', () async {
    final selected = Completer<List<XFile>>();
    final account = FakeAccountRepository();
    final container = ProviderContainer(
      overrides: [
        ...testAppOverrides(account: account),
        imagePickerProvider.overrideWithValue(_Picker(selected)),
      ],
    );
    addTearDown(container.dispose);
    final composer = container.read(composerControllerProvider.notifier);
    composer.setText('draft');
    final pick = composer.pickImage();
    final reset = container.read(dataResetControllerProvider.notifier);
    final clearing = reset.clear();
    expect(container.read(dataResetControllerProvider), true);
    await reset.clear();
    expect(account.clears, 0);
    selected.complete([]);
    await pick;
    expect((await clearing).isRight(), true);
    expect(account.clears, 1);
    expect(container.read(composerControllerProvider), const ComposerState());
    expect(container.read(dataResetControllerProvider), false);
  });

  test('failed cleanup restores controls and can be retried', () async {
    final account = FakeAccountRepository()
      ..failure = const AppFailure.database(message: 'locked');
    final container = ProviderContainer(
      overrides: testAppOverrides(account: account),
    );
    addTearDown(container.dispose);
    final reset = container.read(dataResetControllerProvider.notifier);
    expect((await reset.clear()).isLeft(), true);
    expect(container.read(dataResetControllerProvider), false);
    account.failure = null;
    expect((await reset.clear()).isRight(), true);
    expect(account.clears, 2);
  });

  test('reset returns memory to the new-user starter file', () async {
    final memory = FakeMemoryRepository(seed: {'topic/old.md': 'Old note\n'});
    final container = ProviderContainer(
      overrides: testAppOverrides(memory: memory),
    );
    addTearDown(container.dispose);

    final result = await container
        .read(dataResetControllerProvider.notifier)
        .clear();

    expect(result.isRight(), isTrue);
    expect(memory.contentOf('topic/old.md'), isNull);
    expect(memory.contentOf('user.md'), '用户尚未设置名字，可以引导用户点击头像设置名字和头像。\n');
  });
}

class _Picker extends Fake implements ImagePicker {
  _Picker(this.result);
  final Completer<List<XFile>> result;
  @override
  Future<List<XFile>> pickMultiImage({
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    int? limit,
    bool requestFullMetadata = true,
  }) => result.future;
}
