import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:selfbox/core/testing/app_widget_tester.dart';
import 'package:selfbox/core/theme/app_icons.dart';
import 'package:selfbox/core/widgets/app_icon.dart';

void main() {
  for (final brightness in Brightness.values) {
    testWidgets(
      'Hugeicons inherit theme and expose one semantic label in $brightness',
      (tester) async {
        await tester.pumpPage(
          const IconTheme(
            data: IconThemeData(size: 32, color: Colors.indigo),
            child: Center(
              child: AppIcon(AppIcons.search, semanticLabel: 'Search'),
            ),
          ),
          brightness: brightness,
        );
        final huge = tester.widget<HugeIcon>(find.byType(HugeIcon));
        expect(huge.icon, HugeIcons.strokeRoundedSearch01);
        expect(huge.strokeWidth, AppIconTokens.strokeWidth);
        expect(tester.getSize(find.byType(HugeIcon)), const Size.square(32));
        expect(find.bySemanticsLabel('Search'), findsOneWidget);
        expect(find.byType(Icon), findsNothing);
      },
    );
  }
}
