import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:selfbox/core/theme/app_icons.dart';
import 'package:selfbox/core/theme/message_tokens.dart';
import 'package:selfbox/core/widgets/app_icon.dart';
import 'package:selfbox/features/chat/domain/models/message.dart';
import 'package:selfbox/features/chat/presentation/widgets/message_bubble.dart';
import 'package:selfbox/features/chat/presentation/widgets/message_preview.dart';
import 'package:selfbox/gen/i18n/strings.g.dart';

import '../../../../support/app_widget_tester.dart';
import '../../../../support/icon_finder.dart';

void main() {
  setUpAll(initializeDateFormatting);
  testWidgets('overflow measurement preserves the mounted content', (
    tester,
  ) async {
    var builds = 0;
    await tester.pumpPage(
      SingleChildScrollView(
        child: MessagePreview(
          enabled: true,
          onExpand: () {},
          child: Builder(
            builder: (_) {
              builds++;
              return const SizedBox(width: 200, height: 1000);
            },
          ),
        ),
      ),
    );
    expect(find.byKey(const ValueKey('expand-message')), findsOneWidget);
    expect(builds, 1);
  });
  testWidgets('narrow large text caps after resize and remains expandable', (
    tester,
  ) async {
    await tester.pumpPage(
      SingleChildScrollView(
        child: MessageBubble(
          message: Message(
            id: 4,
            createdAt: kTestNow,
            author: MessageAuthor.ai,
            text: List.filled(30, '中文段落和文本').join('\n\n'),
          ),
          resolveImage: (_) => null,
          onExpand: () {},
        ),
      ),
    );
    tester.view.physicalSize = const Size(280 * 3, 500 * 3);
    tester.platformDispatcher.textScaleFactorTestValue = 1.8;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpAndSettle();
    expect(
      tester.getSize(find.byKey(const ValueKey('message-preview'))).height,
      lessThanOrEqualTo(250),
    );
    expect(find.byKey(const ValueKey('expand-message')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  for (final brightness in Brightness.values) {
    for (final text in [
      'Short reply',
      List.filled(40, 'line').join('\n\n'),
      List.filled(600, 'Long reply ').join(),
      '| Title | Value |\n|---|---|\n${List.filled(35, '| key | value |').join('\n')}',
    ]) {
      testWidgets('$brightness caps actual layout ${text.length}', (
        tester,
      ) async {
        var opened = false;
        await tester.pumpPage(
          SingleChildScrollView(
            child: MessageBubble(
              message: Message(
                id: 1,
                createdAt: kTestNow,
                author: MessageAuthor.ai,
                text: text,
              ),
              resolveImage: (_) => null,
              onExpand: () => opened = true,
            ),
          ),
          brightness: brightness,
        );
        expect(tester.takeException(), isNull);
        final preview = find.byKey(const ValueKey('message-preview'));
        expect(
          tester.getSize(preview).height,
          lessThanOrEqualTo(kPhoneViewport.height / 2),
        );
        if (text == 'Short reply') {
          expect(find.bySemanticsLabel(t.chat.expandMessage), findsNothing);
          expect(find.text(t.chat.expandMessage), findsNothing);
        } else {
          final label = find.text(t.chat.expandMessage);
          expect(label, findsOneWidget);
          final arrow = findAppIcon(AppIcons.next);
          expect(arrow, findsOneWidget);
          expect(
            tester.widget<Text>(label).style?.color,
            MessageTokens.quoteColor(brightness),
          );
          final icon = tester.widget<AppIcon>(arrow);
          expect(icon.color, MessageTokens.quoteColor(brightness));
          expect(
            tester.getCenter(arrow).dx,
            greaterThan(tester.getRect(label).right),
          );
          expect(
            tester.getCenter(arrow).dy,
            closeTo(tester.getCenter(label).dy, 1),
          );
          await tester.tap(find.bySemanticsLabel(t.chat.expandMessage));
          await tester.pumpAndSettle();
          expect(opened, true);
        }
      });
    }
  }
}
