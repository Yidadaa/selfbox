import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:talker_flutter/talker_flutter.dart';

part '../../gen/core/logger/talker_provider.g.dart';

/// The app-wide log sink. `main()` creates the instance before the
/// ProviderScope exists (so framework errors raised during startup are
/// captured) and injects it via `talkerProvider.overrideWithValue`.
/// The default only exists so tests get an isolated, silent instance.
@Riverpod(keepAlive: true)
Talker talker(Ref ref) =>
    TalkerFlutter.init(settings: TalkerSettings(useConsoleLogs: false));
