import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:selfbox/core/widgets/app_action_button.dart';
import 'package:selfbox/core/widgets/app_page_button.dart';
import 'package:selfbox/gen/i18n/strings.g.dart';

import '../../support/app_widget_tester.dart';

void main() {
  for (final brightness in Brightness.values) {
    testWidgets(
      'page button uses standard glass and guards busy in $brightness',
      (tester) async {
        final busy = ValueNotifier(false);
        addTearDown(busy.dispose);
        var taps = 0;
        await tester.pumpPage(
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                ValueListenableBuilder(
                  valueListenable: busy,
                  builder: (_, value, _) => AppPageButton(
                    label: t.common.save,
                    busy: value,
                    onPressed: () => taps++,
                  ),
                ),
                AppActionButton(label: t.common.cancel, onPressed: () {}),
              ],
            ),
          ),
          brightness: brightness,
        );
        final button = find.byType(GlassButton);
        expect(
          tester.widget<GlassButton>(button).quality,
          GlassQuality.standard,
        );
        expect(
          tester.widget<GlassButton>(button).style,
          GlassButtonStyle.filled,
        );
        expect(tester.getSize(button).width, 358);
        expect(tester.getSize(button).height, greaterThanOrEqualTo(48));
        await tester.tap(button);
        expect(taps, 1);
        busy.value = true;
        await tester.pump();
        expect(tester.widget<GlassButton>(button).enabled, isFalse);
        await tester.tap(button);
        expect(taps, 1);
        expect(find.byType(AppActionButton), findsOneWidget);
        busy.value = false;
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    );
  }
}
