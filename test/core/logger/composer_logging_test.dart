import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:selfbox/features/chat/presentation/providers/composer_controller.dart';
import 'package:selfbox/main.dart';
import 'package:talker_flutter/talker_flutter.dart';

import '../../support/app_widget_tester.dart';

void main() {
  test('draft keystrokes never enter the Riverpod log', () {
    final talker = Talker(settings: TalkerSettings(useConsoleLogs: false));
    final container = ProviderContainer(
      overrides: testAppOverrides(),
      observers: [appRiverpodObserver(talker)],
    );
    addTearDown(container.dispose);
    container.listen(composerControllerProvider, (_, _) {});
    final composer = container.read(composerControllerProvider.notifier);
    for (final text in ['private', 'private draft', 'private draft secret']) {
      composer.setText(text);
    }
    expect(
      talker.history.where(
        (entry) =>
            entry.message?.contains('composerControllerProvider') ?? false,
      ),
      isEmpty,
    );
    expect(
      talker.history.where(
        (entry) => entry.message?.contains('private') ?? false,
      ),
      isEmpty,
    );
    expect(
      container.read(composerControllerProvider).text,
      'private draft secret',
    );
  });
}
