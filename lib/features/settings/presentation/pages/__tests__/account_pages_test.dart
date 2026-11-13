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
  testWidgets('Me opens Agent profile and saves both names', (tester) async {
    final account = FakeAccountRepository();
    final container = await tester.pumpApp(account: account);
    container.read(appRouterProvider).go('/me');
    await tester.pumpAndSettle();
    expect(find.text(t.me.storage), findsOneWidget);
    expect(find.text(t.me.providers), findsOneWidget);
    expect(find.text(t.me.about), findsOneWidget);
    await tester.tap(find.text(t.me.editProfile));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(EditableText).first, '');
    await tester.tap(find.text(t.common.save));
    await tester.pumpAndSettle();
    expect(find.text(t.forms.required), findsOneWidget);
    await tester.enterText(find.byType(EditableText).first, 'Momo');
    await tester.enterText(find.byType(EditableText).last, 'Flynn');
    await tester.tap(find.text(t.common.save));
    await tester.pumpAndSettle();
    expect(account.profile.nickname, 'Flynn');
    expect(
      container.read(appRouterProvider).routeInformationProvider.value.uri.path,
      '/me',
    );
    expect(find.text('Momo'), findsOneWidget);
    expect(find.text('Flynn'), findsNothing);
  });

  testWidgets('storage requires confirmation; cancel preserves data', (
    tester,
  ) async {
    final account = FakeAccountRepository();
    final container = await tester.pumpApp(
      account: account,
      locale: AppLocale.zhCn,
    );
    container.read(appRouterProvider).go('/me/storage');
    await tester.pumpAndSettle();
    await tester.tap(find.text(t.me.clearAll));
    await tester.pumpAndSettle();
    expect(find.text(t.me.clearWarning), findsOneWidget);
    final dialog = tester.widget<Dialog>(find.byType(Dialog));
    expect(dialog.backgroundColor, Colors.white);
    expect(
      dialog.shape,
      const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(34)),
      ),
    );
    final dialogBounds = tester.getRect(
      find
          .ancestor(
            of: find.text(t.me.clearWarning),
            matching: find.byType(Material),
          )
          .first,
    );
    final cancel = tester.getRect(
      find.ancestor(
        of: find.text(t.common.cancel),
        matching: find.byType(TextButton),
      ),
    );
    final confirm = tester.getRect(
      find.ancestor(
        of: find.text(t.me.confirmClear),
        matching: find.byType(TextButton),
      ),
    );
    expect(dialogBounds.width, 320);
    final titleBounds = tester.getRect(find.text(t.me.clearWarning));
    expect(titleBounds.left - dialogBounds.left, 32);
    expect(titleBounds.top - dialogBounds.top, 24);
    expect(cancel.height, 48);
    expect(confirm.height, 48);
    expect(cancel.width, confirm.width);
    expect(confirm.left - cancel.right, 8);
    expect(cancel.left - dialogBounds.left, 16);
    expect(dialogBounds.right - confirm.right, 16);
    expect(dialogBounds.bottom - confirm.bottom, 16);
    for (final button in tester.widgetList<TextButton>(
      find.byType(TextButton),
    )) {
      expect(button.style?.shape?.resolve({}), const StadiumBorder());
      expect(button.style?.backgroundColor?.resolve({}), isNotNull);
    }
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

  testWidgets('storage dialog stacks actions when labels need more width', (
    tester,
  ) async {
    final container = await tester.pumpApp();
    container.read(appRouterProvider).go('/me/storage');
    await tester.pumpAndSettle();
    await tester.tap(find.text(t.me.clearAll));
    tester.view.physicalSize = const Size(280 * 3, 844 * 3);
    await tester.pumpAndSettle();

    final cancel = tester.getRect(
      find.ancestor(
        of: find.text(t.common.cancel),
        matching: find.byType(TextButton),
      ),
    );
    final confirm = tester.getRect(
      find.ancestor(
        of: find.text(t.me.confirmClear),
        matching: find.byType(TextButton),
      ),
    );
    expect(confirm.top - cancel.bottom, 8);
    expect(confirm.width, cancel.width);
    final confirmLabel = tester.getRect(find.text(t.me.confirmClear));
    expect(confirmLabel.left, greaterThanOrEqualTo(confirm.left));
    expect(confirmLabel.right, lessThanOrEqualTo(confirm.right));
    expect(confirmLabel.bottom, lessThanOrEqualTo(confirm.bottom));
    expect(tester.takeException(), isNull);
  });

  testWidgets('about shows installed version', (tester) async {
    final container = await tester.pumpApp();
    container.read(appRouterProvider).go('/me/about');
    await tester.pumpAndSettle();
    expect(find.text('0.3.0 (3)'), findsOneWidget);
  });
}
