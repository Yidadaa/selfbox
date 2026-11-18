import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:selfbox/core/theme/sdk_material.dart';
import 'package:selfbox/features/chat/domain/models/message.dart';
import 'package:selfbox/features/chat/presentation/widgets/pinned_messages_list.dart';

import '../../../../support/app_widget_tester.dart';

void main() {
  setUpAll(() => initializeDateFormatting('en'));
  for (final brightness in Brightness.values) {
    testWidgets(
      'both edges fade to transparency without tinting content in $brightness',
      (tester) async {
        final boundaryKey = GlobalKey();
        await tester.pumpPage(
          Center(
            child: SizedBox(
              width: 320,
              height: 240,
              child: RepaintBoundary(
                key: boundaryKey,
                child: PinnedMessagesList(
                  messages: [
                    Message(
                      id: 1,
                      createdAt: kTestNow,
                      author: MessageAuthor.me,
                      text: List.filled(60, 'A long pinned message').join('\n'),
                    ),
                  ],
                ),
              ),
            ),
          ),
          brightness: brightness,
        );
        final list = find.byType(ListView);
        await tester.drag(list, const Offset(0, 200));
        await tester.pumpAndSettle();
        final boundary = tester.renderObject<RenderRepaintBoundary>(
          find.byKey(boundaryKey),
        );
        final image = await boundary.toImage();
        final bytes = await tester.runAsync(image.toByteData);
        expect(bytes, isNotNull);
        final pixels = bytes ?? fail('Unable to capture list pixels');
        int alpha(int y) =>
            pixels.getUint8((y * image.width + image.width - 40) * 4 + 3);
        expect(alpha(0), lessThan(20));
        expect(alpha(12), inExclusiveRange(30, 230));
        expect(alpha(120), 255);
        expect(alpha(image.height - 13), inExclusiveRange(30, 230));
        expect(alpha(image.height - 1), lessThan(20));
        image.dispose();
        expect(tester.takeException(), isNull);
      },
    );
  }
}
