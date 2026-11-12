import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:selfbox/core/error/app_failure.dart';
import 'package:selfbox/core/router/app_router.dart';
import 'package:selfbox/core/testing/app_widget_tester.dart';
import 'package:selfbox/core/testing/fake_ai_settings.dart';
import 'package:selfbox/features/settings/domain/models/ai_settings.dart';
import 'package:selfbox/features/settings/domain/repositories/model_probe.dart';
import 'package:selfbox/gen/i18n/strings.g.dart';
import 'package:selfbox/model_test_providers.dart';

const _provider = ProviderConfig(
  id: 'p1',
  name: 'Gateway',
  format: ApiFormat.chatCompletions,
  baseUrl: 'https://gw.example.com/v1',
);
const _model = ModelConfig(providerId: 'p1', modelId: 'gpt-x', enabled: true);

class _PendingProbe implements ModelProbe {
  final calls = <ModelConfig>[];
  final result = Completer<Either<AppFailure, Unit>>();

  @override
  TaskEither<AppFailure, Unit> test(
    ProviderConfig provider,
    String apiKey,
    ModelConfig model,
  ) {
    calls.add(model);
    return TaskEither(() => result.future);
  }
}

Future<void> _open(
  WidgetTester tester,
  FakeAiSettingsRepository settings,
  ModelProbe probe,
) async {
  final container = await tester.pumpApp(
    settings: settings,
    overrides: [modelProbeProvider.overrideWith((ref) => probe)],
  );
  container.read(appRouterProvider).go('/me/provider?id=p1');
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const ValueKey('model-open-gpt-x')));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows progress then success without changing settings', (
    tester,
  ) async {
    final settings = FakeAiSettingsRepository(
      settings: const AiSettings(providers: [_provider], models: [_model]),
      apiKeys: {'p1': 'secret'},
    );
    final before = settings.current;
    final probe = _PendingProbe();
    await _open(tester, settings, probe);

    final button = find.byKey(const ValueKey('test-model-button'));
    await tester.tap(button);
    await tester.pump();
    expect(probe.calls, hasLength(1));
    expect(find.text(t.settings.model.testing), findsOneWidget);
    await tester.tap(button);
    await tester.pump();
    expect(probe.calls, hasLength(1));

    probe.result.complete(const Right(unit));
    await tester.pumpAndSettle();
    expect(find.text(t.settings.model.available), findsOneWidget);
    expect(settings.current, before);
  });

  testWidgets('failure stays visible in the sheet', (tester) async {
    final settings = FakeAiSettingsRepository(
      settings: const AiSettings(providers: [_provider], models: [_model]),
      apiKeys: {'p1': 'secret'},
    );
    final probe = _PendingProbe();
    await _open(tester, settings, probe);
    await tester.tap(find.byKey(const ValueKey('test-model-button')));
    await tester.pump();

    probe.result.complete(
      const Left(AppFailure.network(message: 'unauthorized', statusCode: 401)),
    );
    await tester.pumpAndSettle();
    expect(find.text(t.settings.model.testFailed), findsOneWidget);
    expect(find.text(t.settings.errors.auth), findsOneWidget);
    expect(find.byType(BottomSheet), findsOneWidget);
  });
}
