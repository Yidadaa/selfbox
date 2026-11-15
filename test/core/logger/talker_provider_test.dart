import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hooks_riverpod/misc.dart' show Override;
import 'package:selfbox/core/logger/talker_provider.dart';
import 'package:talker_flutter/talker_flutter.dart';

ProviderContainer _container({List<Override> overrides = const []}) {
  final container = ProviderContainer(overrides: overrides);
  addTearDown(container.dispose);
  return container;
}

void main() {
  group('talkerProvider', () {
    test('keeps one instance alive for the whole container', () {
      final container = _container();
      expect(
        container.read(talkerProvider),
        same(container.read(talkerProvider)),
      );
    });

    test('uses the instance injected by main()', () {
      final injected = Talker();
      final container = _container(
        overrides: [talkerProvider.overrideWithValue(injected)],
      );
      expect(container.read(talkerProvider), same(injected));
    });

    test('records handled errors in its history', () {
      final container = _container();
      final talker = container.read(talkerProvider)
        ..handle(StateError('boom'), StackTrace.empty);
      expect(talker.history.whereType<TalkerError>(), hasLength(1));
    });
  });
}
