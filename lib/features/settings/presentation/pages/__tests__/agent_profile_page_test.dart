import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:selfbox/core/error/app_failure.dart';
import 'package:selfbox/core/router/app_router.dart';
import 'package:selfbox/core/testing/app_widget_tester.dart';
import 'package:selfbox/core/testing/fake_account_repository.dart';
import 'package:selfbox/core/widgets/app_artwork.dart';
import 'package:selfbox/features/settings/domain/models/user_profile.dart';
import 'package:selfbox/features/settings/presentation/pages/profile_page.dart';
import 'package:selfbox/gen/i18n/strings.g.dart';

void main() {
  testWidgets('failed save retains both drafts and selected avatar for retry', (
    tester,
  ) async {
    final account = FakeAccountRepository()
      ..saveFailure = const AppFailure.database(message: 'disk');
    final container = await tester.pumpApp(account: account);
    container.read(appRouterProvider).go('/me/profile');
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(EditableText).first, 'Momo');
    await tester.enterText(find.byType(EditableText).last, 'Flynn');
    await tester.tap(find.text(t.common.save));
    await tester.pumpAndSettle();
    expect(find.byType(ProfilePage), findsOneWidget);
    expect(find.text('Momo'), findsOneWidget);
    expect(find.text('Flynn'), findsOneWidget);
    expect(account.profile, const UserProfile());
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
    account.saveFailure = null;
    await tester.tap(find.text(t.common.save));
    await tester.pumpAndSettle();
    expect(account.profile.agentName, 'Momo');
    expect(account.profile.nickname, 'Flynn');
  });

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
        await tester.tap(find.byKey(const ValueKey('chat-header-profile')));
        await tester.pumpAndSettle();
        expect(find.byType(ProfilePage), findsOneWidget);
        expect(find.text(t.me.agentName), findsOneWidget);
        expect(find.text(t.me.callMe), findsOneWidget);
        final fields = find.byType(EditableText);
        expect(fields, findsNWidgets(2));
        await tester.enterText(fields.first, 'Momo');
        await tester.enterText(fields.last, 'Casey');
        await tester.tap(find.text(t.common.save));
        await tester.pumpAndSettle();
        expect(account.profile.agentName, 'Momo');
        expect(account.profile.nickname, 'Casey');
        expect(account.profile.avatar, 'media/old.jpg');
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
      findsOneWidget,
    );
    await tester.tap(find.text(t.common.save));
    await tester.pumpAndSettle();
    expect(account.profile.agentAvatar, 'preset:working');
  });
}
