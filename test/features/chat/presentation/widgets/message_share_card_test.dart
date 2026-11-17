import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:selfbox/core/theme/message_tokens.dart';
import 'package:selfbox/core/widgets/app_artwork.dart';
import 'package:selfbox/features/chat/domain/models/message.dart';
import 'package:selfbox/features/chat/presentation/widgets/message_share_card.dart';
import 'package:selfbox/features/chat/presentation/widgets/message_text_bubble.dart';

import '../../../../support/app_widget_tester.dart';

void main() {
  for (final brightness in Brightness.values) {
    testWidgets(
      'share card keeps full content and centered branding $brightness',
      (tester) async {
        await tester.pumpPage(
          SingleChildScrollView(
            child: MessageShareCard(
              message: Message(
                id: 7,
                createdAt: kTestNow,
                author: MessageAuthor.ai,
                text:
                    '${List.filled(30, 'A thoughtful paragraph.').join('\n\n')}\n\nLAST LINE',
              ),
            ),
          ),
          brightness: brightness,
        );
        final card = find.byType(MessageTextBubble);
        final art = find.byWidgetPredicate(
          (widget) =>
              widget is AppArtwork && widget.artwork == BrandArt.welcome,
        );
        final body = tester.getRect(card);
        final dog = tester.getRect(art);
        expect(dog.center.dx, body.center.dx);
        expect(dog.top, greaterThan(0));
        expect(dog.bottom, greaterThan(body.top));
        expect(dog.bottom - body.top, lessThan(dog.height / 3));
        final surface = tester.widget<DecoratedBox>(
          find.byKey(const ValueKey('message-surface')),
        );
        expect(
          (surface.decoration as ShapeDecoration).shape,
          RoundedSuperellipseBorder(
            borderRadius: BorderRadius.circular(MessageTokens.radius),
          ),
        );
        expect(find.text('LAST LINE', findRichText: true), findsOneWidget);
        final footer = tester.getRect(
          find.byKey(const ValueKey('share-brand')),
        );
        expect(footer.center.dx, body.center.dx);
        expect(footer.top, greaterThan(body.bottom));
        expect(find.text('小懒'), findsOneWidget);
        expect(find.byKey(const ValueKey('expand-message')), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
