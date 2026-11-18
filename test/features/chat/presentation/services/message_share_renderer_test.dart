import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:selfbox/core/theme/message_share_tokens.dart';
import 'package:selfbox/core/theme/sdk_material.dart';
import 'package:selfbox/features/chat/domain/models/message.dart';
import 'package:selfbox/features/chat/presentation/services/message_share_renderer.dart';

import '../../../../support/app_widget_tester.dart';

void main() {
  for (final brightness in Brightness.values) {
    testWidgets('exports a full-height PNG in $brightness', (tester) async {
      await tester.pumpPage(
        const Text('reader stays here'),
        brightness: brightness,
      );
      final context = tester.element(find.text('reader stays here'));
      final result = await tester.runAsync(
        () => renderMessageShare(
          context,
          Message(
            id: 3,
            createdAt: kTestNow,
            author: MessageAuthor.ai,
            text:
                '```dart\nfinal answer = 42;\n```\n\n'
                '| Item | Value |\n| --- | --- |\n| A | 42 |\n\n'
                '${List.filled(32, 'A paragraph to share.').join('\n\n')}',
          ),
        ).run(),
      );
      final bytes = result?.getRight().toNullable();
      expect(bytes, isNotNull, reason: '$result');
      if (bytes == null) return;
      final codec = await tester.runAsync(
        () => ui.instantiateImageCodec(bytes),
      );
      final frame = await tester.runAsync(() async => codec?.getNextFrame());
      expect(
        frame?.image.width,
        MessageShareTokens.width * MessageShareTokens.pixelRatio,
      );
      expect(
        frame?.image.height,
        greaterThan(kPhoneViewport.height * MessageShareTokens.pixelRatio),
      );
      frame?.image.dispose();
      codec?.dispose();
      await tester.pumpAndSettle();
      expect(find.text('reader stays here'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets(
    'oversized message fails before raster allocation and leaves page intact',
    (tester) async {
      await tester.pumpPage(const Text('reader stays here'));
      final context = tester.element(find.text('reader stays here'));
      final result = await tester.runAsync(
        () => renderMessageShare(
          context,
          Message(
            id: 3,
            createdAt: kTestNow,
            author: MessageAuthor.ai,
            text: List.filled(1000, 'A paragraph to share.').join('\n\n'),
          ),
        ).run(),
      );
      expect(result?.isLeft(), true);
      expect(
        result?.getLeft().toNullable().toString(),
        contains(messageShareTooLong),
      );
      await tester.pumpAndSettle();
      expect(find.text('reader stays here'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
