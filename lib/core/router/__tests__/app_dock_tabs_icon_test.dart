import 'package:flutter_test/flutter_test.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:selfbox/core/router/app_dock_tabs.dart';
import 'package:selfbox/core/testing/app_widget_tester.dart';
import 'package:selfbox/core/testing/icon_finder.dart';
import 'package:selfbox/core/theme/app_icons.dart';

void main() {
  testWidgets('dock uses the selected Hugeicons glyphs', (tester) async {
    await tester.pumpApp();
    expect(find.byType(AppDockTabs), findsOneWidget);
    expect(AppIcons.chat, HugeIcons.strokeRoundedMessage02);
    expect(AppIcons.memory, HugeIcons.strokeRoundedCards02);
    expect(AppIcons.profile, HugeIcons.strokeRoundedBlackHole01);
    expect(findAppIcon(AppIcons.chat), findsOneWidget);
    expect(findAppIcon(AppIcons.memory), findsOneWidget);
    expect(findAppIcon(AppIcons.profile), findsOneWidget);
  });
}
