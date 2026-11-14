import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:selfbox/core/forms/glass_reactive_text_field.dart';
import 'package:selfbox/core/router/app_router.dart';
import 'package:selfbox/core/testing/app_widget_tester.dart';
import 'package:selfbox/core/testing/fake_account_repository.dart';
import 'package:selfbox/core/testing/fake_ai_settings.dart';
import 'package:selfbox/core/testing/fake_app_preferences_repository.dart';
import 'package:selfbox/core/widgets/app_page_button.dart';
import 'package:selfbox/features/chat/presentation/pages/chat_page.dart';
import 'package:selfbox/features/settings/domain/models/ai_settings.dart';
import 'package:selfbox/features/settings/presentation/pages/ai_providers_page.dart';
import 'package:selfbox/features/settings/presentation/pages/onboarding_page.dart';
import 'package:selfbox/features/settings/presentation/pages/provider_page.dart';
import 'package:selfbox/features/settings/presentation/providers/app_preferences_controller.dart';
import 'package:selfbox/gen/i18n/strings.g.dart';

Future<void> _next(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('onboarding-next')));
  await tester.pumpAndSettle();
}

void main() {
  for (final theme in Brightness.values) {
    for (final locale in AppLocale.values) {
      testWidgets('first run personalizes and skips AI in $theme/$locale', (
        tester,
      ) async {
        tester.platformDispatcher.platformBrightnessTestValue = theme;
        addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
        final account = FakeAccountRepository();
        final preferences = FakeAppPreferencesRepository();
        final container = await tester.pumpApp(
          firstRun: true,
          account: account,
          preferences: preferences,
          locale: locale,
        );
        expect(find.byType(OnboardingPage), findsOneWidget);
        expect(find.byType(ChatPage), findsNothing);
        final router = container.read(appRouterProvider);
        router.go('/memory');
        await tester.pumpAndSettle();
        expect(find.byType(OnboardingPage), findsOneWidget);
        await _next(tester);
        expect(find.byType(EditableText), findsOneWidget);
        await tester.enterText(find.byType(EditableText), 'Momo');
        await tester.tap(find.byKey(const ValueKey('onboarding-avatar')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('avatar-preset-reading')));
        await tester.pumpAndSettle();
        await _next(tester);
        await tester.enterText(find.byType(EditableText), 'Flynn');
        await tester.tap(find.byKey(const ValueKey('onboarding-back')));
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<EditableText>(find.byType(EditableText))
              .controller
              .text,
          'Momo',
        );
        await _next(tester);
        expect(
          tester
              .widget<EditableText>(find.byType(EditableText))
              .controller
              .text,
          'Flynn',
        );
        await _next(tester);
        await tester.tap(find.byKey(const ValueKey('onboarding-skip')));
        await tester.pumpAndSettle();
        expect(find.byType(ChatPage), findsOneWidget);
        expect(account.profile.agentName, 'Momo');
        expect(account.profile.nickname, 'Flynn');
        expect(account.profile.agentAvatar, 'preset:reading');
        expect(preferences.current.onboardingCompleted, isTrue);
        router.go('/onboarding');
        await tester.pumpAndSettle();
        expect(find.byType(ChatPage), findsOneWidget);
        expect(
          container.read(appPreferencesControllerProvider).onboardingCompleted,
          isTrue,
        );
      });
    }
  }

  testWidgets('AI setup returns to the draft and recognizes an enabled model', (
    tester,
  ) async {
    final settings = FakeAiSettingsRepository();
    await tester.pumpApp(firstRun: true, settings: settings);
    for (var i = 0; i < 3; i++) {
      await _next(tester);
    }
    await _next(tester);
    expect(find.byType(AiProvidersPage), findsOneWidget);
    await tester.tap(find.text(t.settings.addProvider));
    await tester.pumpAndSettle();
    expect(find.byType(ProviderPage), findsOneWidget);
    await tester.tap(find.bySemanticsLabel(t.common.close).first);
    await tester.pumpAndSettle();
    await settings
        .save(
          const AiSettings(
            providers: [
              ProviderConfig(
                id: 'p',
                name: 'Demo',
                format: ApiFormat.chatCompletions,
                baseUrl: 'https://example.com',
              ),
            ],
            models: [
              ModelConfig(providerId: 'p', modelId: 'model-a', enabled: true),
            ],
          ),
        )
        .run();
    await tester.tap(find.bySemanticsLabel(t.common.close).first);
    await tester.pumpAndSettle();
    expect(find.text('model-a'), findsOneWidget);
    expect(find.text(t.onboarding.start), findsOneWidget);
    await _next(tester);
    expect(find.byType(ChatPage), findsOneWidget);
  });

  for (final animations in [true, false]) {
    testWidgets(
      'small keyboard layout and step transitions with animations=$animations',
      (tester) async {
        final container = await tester.pumpApp(firstRun: true);
        if (!animations) {
          await container
              .read(appPreferencesControllerProvider.notifier)
              .setAnimationsEnabled(false);
          await tester.pumpAndSettle();
        }
        tester.view.physicalSize = const Size(840, 1950);
        tester.platformDispatcher.textScaleFactorTestValue = 1.5;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('onboarding-next')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        if (animations) {
          expect(
            find.byKey(const ValueKey('onboarding-step-0')),
            findsOneWidget,
          );
          expect(
            find.byKey(const ValueKey('onboarding-step-1')),
            findsOneWidget,
          );
        } else {
          expect(find.byKey(const ValueKey('onboarding-step-0')), findsNothing);
        }
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(EditableText), '');
        tester.view.viewInsets = const FakeViewPadding(bottom: 750);
        await tester.pumpAndSettle();
        expect(
          tester.getRect(find.byType(EditableText)).bottom,
          lessThanOrEqualTo(
            tester.getRect(find.byKey(const ValueKey('onboarding-next'))).top,
          ),
        );
        final fieldBounds = tester.getRect(
          find.byType(GlassReactiveTextField<String>),
        );
        final viewportBounds = tester.getRect(
          find.byType(SingleChildScrollView).first,
        );
        expect(fieldBounds.bottom, lessThanOrEqualTo(viewportBounds.bottom));
        expect(fieldBounds.top, greaterThanOrEqualTo(viewportBounds.top));
        await _next(tester);
        expect(find.text(t.forms.required), findsOneWidget);
        await tester.enterText(find.byType(EditableText), 'Dozy');
        await _next(tester);
        final button = tester.getRect(
          find.byKey(const ValueKey('onboarding-next')),
        );
        expect(button.bottom, lessThanOrEqualTo(650 - 250));
        expect(
          tester.getSize(find.byType(AppPageButton)).height,
          greaterThanOrEqualTo(48),
        );
        expect(tester.takeException(), isNull);
      },
    );
  }
}
