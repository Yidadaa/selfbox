import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hooks_riverpod/misc.dart' show Override;

class ScreenshotFixture {
  const ScreenshotFixture({
    required this.name,
    required this.location,
    this.overrides = _none,
    this.setUp,
  });

  final String name;
  final String location;
  final List<Override> Function() overrides;
  final Future<void> Function(WidgetTester tester, ProviderContainer container)?
  setUp;

  static List<Override> _none() => const [];
}

final screenshotFixtures = <ScreenshotFixture>[
  const ScreenshotFixture(name: 'chat_empty', location: '/chat'),
  const ScreenshotFixture(name: 'memory_empty', location: '/memory'),
  const ScreenshotFixture(name: 'me', location: '/me'),
];
