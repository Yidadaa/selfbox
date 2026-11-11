import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:talker_flutter/talker_flutter.dart';
import 'package:talker_riverpod_logger/talker_riverpod_logger.dart';

import 'app.dart';
import 'core/logger/talker_provider.dart';
import 'gen/i18n/strings.g.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Created before the ProviderScope so errors thrown during startup are
  // captured too; the same instance is injected into Riverpod below.
  final talker = TalkerFlutter.init();
  FlutterError.onError = (details) =>
      talker.handle(details.exception, details.stack, 'FlutterError');
  PlatformDispatcher.instance.onError = (error, stack) {
    talker.handle(error, stack, 'Uncaught platform error');
    return true;
  };

  LocaleSettings.useDeviceLocaleSync();
  await LiquidGlassWidgets.initialize();

  runApp(
    ProviderScope(
      overrides: [talkerProvider.overrideWithValue(talker)],
      observers: [TalkerRiverpodObserver(talker: talker)],
      child: TranslationProvider(
        child: LiquidGlassWidgets.wrap(
          brightnessResolver: Theme.maybeBrightnessOf,
          child: const SelfboxApp(),
        ),
      ),
    ),
  );
}
