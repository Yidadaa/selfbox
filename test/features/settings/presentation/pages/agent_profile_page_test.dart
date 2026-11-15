import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:selfbox/core/error/app_failure.dart';
import 'package:selfbox/core/router/app_router.dart';
import 'package:selfbox/core/widgets/app_artwork.dart';
import 'package:selfbox/features/settings/domain/models/ai_settings.dart';
import 'package:selfbox/features/settings/domain/models/user_profile.dart';
import 'package:selfbox/features/settings/presentation/pages/profile_page.dart';
import 'package:selfbox/features/settings/presentation/providers/account_providers.dart';
import 'package:selfbox/gen/i18n/strings.g.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../../support/app_widget_tester.dart';
import '../../../../support/fake_account_repository.dart';
import '../../../../support/fake_ai_settings.dart';

void main() {
  for (final failureAt in ['profile', 'prompt']) {
    testWidgets(
      'failed $failureAt save retains names, prompt and avatar for retry',
      (tester) async {
        final account = FakeAccountRepository();
        final settings = _FailingSettings()..failSave = failureAt == 'prompt';
        if (failureAt == 'profile') {
          account.saveFailure = const AppFailure.database(message: 'disk');
        }
        final container = await tester.pumpApp(
          account: account,
          settings: settings,
        );
        container.read(appRouterProvider).go('/me/profile');
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(EditableText).first, 'Momo');
        await tester.enterText(find.byType(EditableText).at(1), 'Flynn');
        await tester.enterText(
          find.byType(EditableText).last,
          'Keep this draft',
        );
        await tester.tap(find.text(t.me.changeAvatar));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('avatar-preset-working')));
        await tester.pumpAndSettle();
        await tester.tap(find.text(t.common.save));
        await tester.pumpAndSettle();
        expect(find.byType(ProfilePage), findsOneWidget);
        expect(find.text('Momo'), findsOneWidget);
        expect(find.text('Flynn'), findsOneWidget);
        expect(account.profile, const UserProfile());
        expect(
          tester
              .widget<EditableText>(find.byType(EditableText).last)
              .controller
              .text,
          'Keep this draft',
        );
        expect(
          find.byWidgetPredicate(
            (widget) =>
                widget is AppArtwork && widget.artwork == BrandArt.working,
          ),
          findsNWidgets(2),
        );
        expect(
          settings.current.customPrompt,
          failureAt == 'prompt' ? '' : 'Keep this draft',
        );
        await tester.pump(const Duration(seconds: 4));
        await tester.pumpAndSettle();
        account.saveFailure = null;
        settings.failSave = false;
        await tester.tap(find.text(t.common.save));
        await tester.pumpAndSettle();
        expect(account.profile.agentName, 'Momo');
        expect(account.profile.nickname, 'Flynn');
        expect(account.profile.agentAvatar, 'preset:working');
        expect(settings.current.customPrompt, 'Keep this draft');
      },
    );
  }

  testWidgets('saving default Agent preserves language-dependent name', (
    tester,
  ) async {
    final account = FakeAccountRepository();
    final container = await tester.pumpApp(account: account);
    container.read(appRouterProvider).go('/me/profile');
    await tester.pumpAndSettle();
    await tester.tap(find.text(t.common.save));
    await tester.pumpAndSettle();
    expect(account.profile.agentName, isEmpty);
    expect(account.profile.nickname, isEmpty);
    container.read(appRouterProvider).go('/chat');
    LocaleSettings.setLocaleSync(AppLocale.zhCn);
    await tester.pumpAndSettle();
    expect(find.text('小懒'), findsOneWidget);
    LocaleSettings.setLocaleSync(AppLocale.en);
    await tester.pumpAndSettle();
    expect(find.text('Dozy'), findsOneWidget);
  });
  for (final locale in AppLocale.values) {
    testWidgets(
      'headers use localized Agent identity and edit both names in $locale',
      (tester) async {
        final account = FakeAccountRepository()
          ..profile = const UserProfile(
            nickname: 'Flynn',
            avatar: 'media/old.jpg',
          );
        final container = await tester.pumpApp(
          account: account,
          locale: locale,
        );
        expect(find.text(t.me.agentDefaultName), findsOneWidget);
        expect(find.text('Flynn'), findsNothing);
        if (locale == AppLocale.en) {
          await tester.tap(find.byKey(const ValueKey('chat-header-profile')));
        } else {
          container.read(appRouterProvider).go('/me');
          await tester.pumpAndSettle();
          expect(find.text(t.me.storage), findsOneWidget);
          expect(find.text(t.me.providers), findsOneWidget);
          expect(find.text(t.me.about), findsOneWidget);
          await tester.tap(find.text(t.me.editProfile));
        }
        await tester.pumpAndSettle();
        expect(find.byType(ProfilePage), findsOneWidget);
        expect(find.text(t.me.agentName), findsOneWidget);
        expect(find.text(t.me.callMe), findsOneWidget);
        final fields = find.byType(EditableText);
        expect(fields, findsNWidgets(3));
        await tester.enterText(fields.first, '');
        await tester.tap(find.text(t.common.save));
        await tester.pumpAndSettle();
        expect(find.text(t.forms.required), findsOneWidget);
        await tester.enterText(fields.first, 'Momo');
        await tester.enterText(fields.at(1), 'Casey');
        await tester.tap(find.text(t.common.save));
        await tester.pumpAndSettle();
        expect(account.profile.agentName, 'Momo');
        expect(account.profile.nickname, 'Casey');
        expect(account.profile.avatar, 'media/old.jpg');
        if (locale == AppLocale.zhCn) {
          expect(
            container
                .read(appRouterProvider)
                .routeInformationProvider
                .value
                .uri
                .path,
            '/me',
          );
        }
        expect(find.text('Momo'), findsOneWidget);
        container.read(appRouterProvider).go('/me');
        await tester.pumpAndSettle();
        expect(find.text('Momo'), findsOneWidget);
        expect(find.text('Casey'), findsNothing);
      },
    );
  }

  testWidgets('preset chooser ends with gallery and saves a chosen state', (
    tester,
  ) async {
    final account = FakeAccountRepository();
    final container = await tester.pumpApp(account: account);
    container.read(appRouterProvider).go('/me/profile');
    await tester.pumpAndSettle();
    await tester.tap(find.text(t.me.changeAvatar));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('avatar-gallery')), findsOneWidget);
    expect(find.byKey(const ValueKey('avatar-preset-working')), findsOneWidget);
    expect(find.byKey(const ValueKey('avatar-preset-playing')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('avatar-preset-working')));
    await tester.pumpAndSettle();
    expect(
      find.byWidgetPredicate(
        (w) => w is AppArtwork && w.artwork == BrandArt.working,
      ),
      findsNWidgets(2),
    );
    await tester.tap(find.text(t.common.save));
    await tester.pumpAndSettle();
    expect(account.profile.agentAvatar, 'preset:working');
  });
  testWidgets(
    'profile loading keeps its form skeleton and recovers from error',
    (tester) async {
      final pending = Completer<UserProfile>();
      var attempts = 0;
      final container = await tester.pumpApp(
        settle: false,
        overrides: [
          userProfileProvider.overrideWith((ref) {
            attempts++;
            return attempts == 1
                ? pending.future
                : Future.value(const UserProfile(nickname: 'Recovered'));
          }),
        ],
      );
      container.read(appRouterProvider).go('/me/profile');
      await tester.pump(const Duration(milliseconds: 400));
      expect(
        find.byWidgetPredicate(
          (widget) => widget is Skeletonizer && widget.enabled,
        ),
        findsWidgets,
      );
      pending.completeError(StateError('disk'));
      await tester.pumpAndSettle();
      expect(find.text(t.common.retry), findsOneWidget);
      await tester.tap(find.text(t.common.retry));
      await tester.pumpAndSettle();
      expect(find.text('Recovered'), findsOneWidget);
    },
  );
}

class _FailingSettings extends FakeAiSettingsRepository {
  bool failSave = true;
  @override
  TaskEither<AppFailure, Unit> save(AiSettings settings) => failSave
      ? TaskEither.left(const AppFailure.database(message: 'disk full'))
      : super.save(settings);
}
