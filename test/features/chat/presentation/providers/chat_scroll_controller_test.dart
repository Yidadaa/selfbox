import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:selfbox/features/chat/presentation/providers/chat_scroll_controller.dart';

void main() {
  test('timeline and dock share one container-scoped scroll controller', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final controller = container.read(chatScrollControllerProvider);
    expect(container.read(chatScrollControllerProvider), same(controller));
    expect(controller.hasClients, isFalse);
    final other = ProviderContainer();
    addTearDown(other.dispose);
    expect(other.read(chatScrollControllerProvider), isNot(same(controller)));
  });
}
