import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:selfbox/core/logger/talker_provider.dart';
import 'package:selfbox/features/settings/presentation/pages/talker_page.dart';
import 'package:selfbox/gen/i18n/strings.g.dart';
import 'package:talker_flutter/talker_flutter.dart';

import '../../../../support/app_widget_tester.dart';

void main() {
  testWidgets('Talker page shows the shared log with the current theme', (
    tester,
  ) async {
    final container = await tester.pumpPage(const TalkerPage());
    final talker = container.read(talkerProvider);
    expect(
      tester.widget<TalkerBuilder>(find.byType(TalkerBuilder)).talker,
      same(talker),
    );
    talker.info('hello-log');
    talker.warning('warning-log');
    await tester.pumpAndSettle();
    expect(find.textContaining('hello-log'), findsWidgets);
    await tester.enterText(find.byType(EditableText).first, 'warning-log');
    await tester.pumpAndSettle();
    expect(find.textContaining('hello-log'), findsNothing);
    expect(find.textContaining('warning-log'), findsWidgets);
    expect(find.byType(Icon), findsNothing);
    await tester.tap(find.byKey(const ValueKey('log-actions')));
    await tester.pumpAndSettle();
    expect(find.text(t.logs.copyAll), findsOneWidget);
    expect(find.text(t.logs.share), findsOneWidget);
    expect(find.byType(Icon), findsNothing);
  });
}
