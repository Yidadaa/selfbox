import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:selfbox/core/testing/app_widget_tester.dart';
import 'package:selfbox/features/settings/domain/models/app_preferences.dart';
import 'package:selfbox/features/settings/presentation/providers/app_preferences_controller.dart';

void main() {
  testWidgets(
    'developer unlock preserves MaterialApp but theme changes apply',
    (tester) async {
      final container = await tester.pumpApp();
      final application = tester.widget<MaterialApp>(find.byType(MaterialApp));
      final preferences = container.read(
        appPreferencesControllerProvider.notifier,
      );
      await preferences.unlockDeveloperTools();
      await tester.pumpAndSettle();
      expect(
        tester.widget<MaterialApp>(find.byType(MaterialApp)),
        same(application),
      );
      await preferences.setTheme(AppThemeChoice.light);
      await tester.pumpAndSettle();
      expect(
        tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
        ThemeMode.light,
      );
    },
  );
}
