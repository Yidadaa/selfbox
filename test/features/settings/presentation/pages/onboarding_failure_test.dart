import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:selfbox/core/error/app_failure.dart';
import 'package:selfbox/core/theme/sdk_material.dart';
import 'package:selfbox/features/chat/presentation/pages/chat_page.dart';
import 'package:selfbox/features/settings/domain/models/user_profile.dart';
import 'package:selfbox/features/settings/presentation/pages/onboarding_page.dart';
import 'package:selfbox/features/settings/presentation/providers/account_providers.dart';
import 'package:selfbox/features/settings/presentation/providers/app_preferences_controller.dart';
import 'package:selfbox/gen/i18n/strings.g.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../../support/app_widget_tester.dart';
import '../../../../support/fake_account_repository.dart';
import '../../../../support/fake_app_preferences_repository.dart';

void main() {
  testWidgets('loading is inert and profile read failure offers one retry', (
    tester,
  ) async {
    final pending = Completer<UserProfile>();
    var attempts = 0;
    await tester.pumpApp(
      firstRun: true,
      settle: false,
      overrides: [
        userProfileProvider.overrideWith((ref) {
          attempts++;
          return attempts == 1
              ? pending.future
              : Future.value(const UserProfile());
        }),
      ],
    );
    expect(
      find.byWidgetPredicate(
        (widget) => widget is Skeletonizer && widget.enabled,
      ),
      findsWidgets,
    );
    expect(find.byType(ChatPage), findsNothing);
    pending.completeError(StateError('disk'));
    await tester.pumpAndSettle();
    expect(find.text(t.settings.errors.generic), findsOneWidget);
    expect(find.text(t.common.retry), findsOneWidget);
    await tester.tap(find.text(t.common.retry));
    await tester.pumpAndSettle();
    expect(find.text(t.onboarding.welcomeTitle), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'failed completion retains drafts and back navigation for retry',
    (tester) async {
      final account = FakeAccountRepository();
      final preferences = FakeAppPreferencesRepository()
        ..failure = const AppFailure.database(message: 'full');
      final container = await tester.pumpApp(
        firstRun: true,
        account: account,
        preferences: preferences,
      );
      await tester.tap(find.byKey(const ValueKey('onboarding-next')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(EditableText), 'Momo');
      for (var i = 0; i < 2; i++) {
        await tester.tap(find.byKey(const ValueKey('onboarding-next')));
        await tester.pumpAndSettle();
      }
      await tester.tap(find.byKey(const ValueKey('onboarding-skip')));
      await tester.pumpAndSettle();
      expect(find.byType(OnboardingPage), findsOneWidget);
      expect(find.text(t.settings.errors.generic), findsOneWidget);
      expect(
        container.read(appPreferencesControllerProvider).onboardingCompleted,
        isFalse,
      );
      for (var i = 0; i < 2; i++) {
        await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
          SystemChannels.navigation.name,
          SystemChannels.navigation.codec.encodeMethodCall(
            const MethodCall('popRoute'),
          ),
          null,
        );
        await tester.pumpAndSettle();
      }
      expect(
        tester.widget<EditableText>(find.byType(EditableText)).controller.text,
        'Momo',
      );
      for (var i = 0; i < 2; i++) {
        await tester.tap(find.byKey(const ValueKey('onboarding-next')));
        await tester.pumpAndSettle();
      }
      preferences.failure = null;
      await tester.tap(find.byKey(const ValueKey('onboarding-skip')));
      await tester.pumpAndSettle();
      expect(find.byType(ChatPage), findsOneWidget);
      expect(account.profile.agentName, 'Momo');
      expect(account.profile.nickname, isEmpty);
    },
  );
}
