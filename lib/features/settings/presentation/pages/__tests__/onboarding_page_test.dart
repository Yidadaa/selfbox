import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:selfbox/core/forms/glass_reactive_text_field.dart';
import 'package:selfbox/core/router/app_router.dart';
import 'package:selfbox/core/testing/app_widget_tester.dart';
import 'package:selfbox/core/testing/fake_account_repository.dart';
import 'package:selfbox/core/testing/fake_ai_settings.dart';
import 'package:selfbox/core/testing/fake_app_preferences_repository.dart';
import 'package:selfbox/core/testing/icon_finder.dart';
import 'package:selfbox/core/theme/app_icons.dart';
import 'package:selfbox/core/theme/app_spacing.dart';
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
  for (final brightness in Brightness.values) {
    for (final locale in AppLocale.values) {
      testWidgets(
        'inline arrow, unframed progress bars and clean copy in $brightness/$locale',
        (tester) async {
          tester.platformDispatcher.platformBrightnessTestValue = brightness;
          addTearDown(
            tester.platformDispatcher.clearPlatformBrightnessTestValue,
          );
          await tester.pumpApp(firstRun: true, locale: locale);

          final copy = [
            t.onboarding.welcomeTitle,
            t.onboarding.welcomeSubtitle,
            t.onboarding.identityTitle,
            t.onboarding.identitySubtitle,
            t.onboarding.nicknameTitle,
            t.onboarding.nicknameSubtitle,
            t.onboarding.connectTitle(name: 'Flynn'),
            t.onboarding.connectSubtitle,
            t.onboarding.begin,
            t.onboarding.next,
            t.onboarding.configure,
            t.onboarding.start,
            t.onboarding.skip,
            t.onboarding.back,
            t.onboarding.progress(current: 1, total: 4),
          ];
          for (final text in copy) {
            expect(RegExp(r'[.!?。！？；，:;]$').hasMatch(text), isFalse);
          }
          expect(find.text(t.onboarding.welcomeSubtitle), findsOneWidget);
          expect(
            t.onboarding.welcomeSubtitle,
            locale == AppLocale.zhCn
                ? '有时我在睡觉，有时我陪你'
                : 'Sometimes I nap, sometimes I keep you company',
          );
          expect(
            t.onboarding.nicknameSubtitle,
            locale == AppLocale.zhCn ? '这样我们就是朋友了' : 'Now we’re friends',
          );
          final progress = find.byKey(const ValueKey('onboarding-progress'));
          final bars = find.descendant(
            of: progress,
            matching: find.byType(DecoratedBox),
          );
          expect(bars, findsNWidgets(4));
          for (final bar in bars.evaluate()) {
            expect(tester.getSize(find.byWidget(bar.widget)).height, 4);
          }
          final activeBar = tester.widget<AnimatedContainer>(
            find.byKey(const ValueKey('onboarding-progress-0')),
          );
          expect(
            (activeBar.decoration as BoxDecoration).color,
            Theme.of(tester.element(progress)).colorScheme.onSurface,
          );

          await _next(tester);
          expect(find.text(t.me.changeAvatar), findsNothing);
          await _next(tester);
          expect(find.text(t.onboarding.nicknameSubtitle), findsOneWidget);
          expect(find.text(t.me.changeAvatar), findsNothing);
          final back = tester.getRect(
            find.byKey(const ValueKey('onboarding-back')),
          );
          final next = tester.getRect(
            find.byKey(const ValueKey('onboarding-next')),
          );
          expect(back.width, back.height);
          expect(next.height, back.height);
          expect(back.center.dy, closeTo(next.center.dy, 0.01));
          expect(next.left - back.right, AppSpacing.md);
          expect(
            tester.getRect(findAppIcon(AppIcons.next)).left -
                tester.getRect(find.text(t.onboarding.next)).right,
            closeTo(AppSpacing.xxs, 0.01),
          );
          final content = tester
              .getRect(findAppIcon(AppIcons.next))
              .expandToInclude(tester.getRect(find.text(t.onboarding.next)));
          expect(content.center.dx, closeTo(next.center.dx, 0.01));
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

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
        expect(
          find.text(t.onboarding.connectTitle(name: 'Flynn')),
          findsOneWidget,
        );
        expect(find.text(t.onboarding.connectSubtitle), findsOneWidget);
        expect(find.text(t.me.providers), findsNothing);
        expect(find.text(t.onboarding.configure), findsOneWidget);
        expect(t.onboarding.skip, locale == AppLocale.zhCn ? '跳过' : 'Skip');
        if (locale == AppLocale.zhCn) {
          expect(find.text('Flynn，我准备好了'), findsOneWidget);
          expect(find.text('头好痒，好像要长脑子了'), findsOneWidget);
        }
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
    expect(find.text(t.me.providers), findsNothing);
    expect(find.text(t.onboarding.connectTitleUnnamed), findsOneWidget);
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
        expect(tester.takeException(), isNull);
      },
    );
  }
}
