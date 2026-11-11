import 'package:riverpod_annotation/riverpod_annotation.dart';

part '../../gen/core/time/clock.g.dart';

/// Injectable "now": widgets and services never call `DateTime.now()`
/// directly, so relative labels ("today") are deterministic in tests.
@Riverpod(keepAlive: true)
DateTime Function() clock(Ref ref) => DateTime.now;
