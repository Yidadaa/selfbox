import 'package:flutter_test/flutter_test.dart';
import 'package:selfbox/core/router/app_router.dart';
import 'package:selfbox/core/testing/app_widget_tester.dart';
import 'package:selfbox/core/testing/fake_account_repository.dart';
import 'package:selfbox/core/widgets/app_confirm_dialog.dart';
import 'package:selfbox/features/settings/domain/models/user_profile.dart';
import 'package:selfbox/features/settings/presentation/providers/account_providers.dart';
import 'package:selfbox/gen/i18n/strings.g.dart';

void main() {
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
    expect(find.byType(AppConfirmDialog), findsOneWidget);
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
}
