import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:selfbox/core/logger/talker_provider.dart';
import 'package:selfbox/core/testing/app_widget_tester.dart';
import 'package:selfbox/features/settings/presentation/pages/talker_page.dart';
import 'package:talker_flutter/talker_flutter.dart';

void main() {
  testWidgets('Talker page shows the shared log with the current theme', (
    tester,
  ) async {
    final container = await tester.pumpPage(const TalkerPage());
    final screen = tester.widget<TalkerScreen>(find.byType(TalkerScreen));
    expect(screen.talker, same(container.read(talkerProvider)));
    expect(
      screen.theme.backgroundColor,
      Theme.of(tester.element(find.byType(TalkerPage))).colorScheme.surface,
    );
  });
}
