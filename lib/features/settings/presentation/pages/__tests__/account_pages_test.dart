import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:selfbox/core/router/app_router.dart';
import 'package:selfbox/core/testing/app_widget_tester.dart';
import 'package:selfbox/core/testing/fake_account_repository.dart';
import 'package:selfbox/features/settings/domain/models/user_profile.dart';
import 'package:selfbox/features/settings/presentation/providers/account_providers.dart';
import 'package:selfbox/gen/i18n/strings.g.dart';
import 'package:skeletonizer/skeletonizer.dart';

void main() {
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

  testWidgets('storage error can retry to an empty usage report', (
    tester,
  ) async {
    var attempts = 0;
    final container = await tester.pumpApp(
      overrides: [
        storageUsageProvider.overrideWith((ref) async {
          if (++attempts == 1) throw StateError('disk');
          return const StorageUsage();
        }),
      ],
    );
    container.read(appRouterProvider).go('/me/storage');
    await tester.pumpAndSettle();
    await tester.tap(find.text(t.common.retry));
    await tester.pumpAndSettle();
    expect(find.text('0 B'), findsNWidgets(5));
    expect(find.text(t.me.clearAll), findsOneWidget);
  });
  testWidgets('Me opens profile and saves a nickname', (tester) async {
    final account = FakeAccountRepository();
    final container = await tester.pumpApp(account: account);
    container.read(appRouterProvider).go('/me');
    await tester.pumpAndSettle();
    expect(find.text(t.me.storage), findsOneWidget);
    expect(find.text(t.me.providers), findsOneWidget);
    expect(find.text(t.me.about), findsOneWidget);
    await tester.tap(find.text(t.me.editProfile));
    await tester.pumpAndSettle();
    await tester.tap(find.text(t.common.save));
    await tester.pumpAndSettle();
    expect(find.text(t.forms.required), findsOneWidget);
    await tester.enterText(find.byType(EditableText), 'Flynn');
    await tester.tap(find.text(t.common.save));
    await tester.pumpAndSettle();
    expect(account.profile.nickname, 'Flynn');
    expect(
      container.read(appRouterProvider).routeInformationProvider.value.uri.path,
      '/me',
    );
    expect(find.text('Flynn'), findsOneWidget);
  });

  testWidgets('storage requires confirmation; cancel preserves data', (
    tester,
  ) async {
    final account = FakeAccountRepository();
    final container = await tester.pumpApp(account: account);
    container.read(appRouterProvider).go('/me/storage');
    await tester.pumpAndSettle();
    await tester.tap(find.text(t.me.clearAll));
    await tester.pumpAndSettle();
    expect(find.text(t.me.clearWarning), findsOneWidget);
    await tester.tap(find.text(t.common.cancel));
    await tester.pumpAndSettle();
    expect(account.clears, 0);
    await tester.tap(find.text(t.me.clearAll));
    await tester.pumpAndSettle();
    await tester.tap(find.text(t.me.confirmClear));
    await tester.pumpAndSettle();
    expect(account.clears, 1);
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
  });

  testWidgets('about shows installed version', (tester) async {
    final container = await tester.pumpApp();
    container.read(appRouterProvider).go('/me/about');
    await tester.pumpAndSettle();
    expect(find.text('0.1.0 (1)'), findsOneWidget);
  });
}
