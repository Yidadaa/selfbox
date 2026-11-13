import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:selfbox/core/router/app_router.dart';
import 'package:selfbox/core/testing/app_widget_tester.dart';
import 'package:selfbox/core/widgets/app_action_button.dart';
import 'package:selfbox/core/widgets/app_confirm_dialog.dart';
import 'package:selfbox/gen/i18n/strings.g.dart';

void main() {
  testWidgets('Me separates developer entries and opens component library', (
    tester,
  ) async {
    final container = await tester.pumpApp();
    container.read(appRouterProvider).go('/me');
    await tester.pumpAndSettle();

    expect(find.text(t.me.logs), findsOneWidget);
    expect(find.text(t.me.componentLibrary), findsOneWidget);
    expect(find.text(t.me.developer), findsOneWidget);

    await tester.tap(find.text(t.me.componentLibrary));
    await tester.pumpAndSettle();
    expect(find.text(t.me.componentLibrary), findsOneWidget);
    expect(find.byType(AppActionButton), findsNWidgets(3));
    expect(find.byType(AppActionIconButton), findsNWidgets(3));
    expect(find.text(t.common.save), findsOneWidget);
    expect(find.text(t.common.cancel), findsOneWidget);
    expect(find.text(t.common.delete), findsOneWidget);

    await tester.tap(find.text(t.me.componentLibraryDialog));
    await tester.pumpAndSettle();
    expect(find.byType(AppActionDialog), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(Dialog),
        matching: find.byType(AppActionButton),
      ),
      findsNWidgets(3),
    );
  });
}
