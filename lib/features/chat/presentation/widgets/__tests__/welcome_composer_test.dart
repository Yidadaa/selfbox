import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:selfbox/core/testing/app_widget_tester.dart';
import 'package:selfbox/core/widgets/app_artwork.dart';
import 'package:selfbox/features/chat/presentation/widgets/chat_composer.dart';
import 'package:selfbox/features/chat/presentation/widgets/welcome_timeline.dart';
import 'package:selfbox/gen/i18n/strings.g.dart';

Finder get _dog => find.byWidgetPredicate(
  (widget) => widget is AppArtwork && widget.artwork == BrandArt.welcome,
);

void main() {
  for (final brightness in Brightness.values) {
    for (final width in [280.0, 390.0]) {
      testWidgets('welcome dog perches above input in $brightness/$width', (
        tester,
      ) async {
        tester.platformDispatcher.platformBrightnessTestValue = brightness;
        addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
        await tester.pumpApp();
        tester.view.physicalSize = Size(width * 3, 844 * 3);
        await tester.pumpAndSettle();
        expect(
          find.descendant(of: find.byType(WelcomeTimeline), matching: _dog),
          findsNothing,
        );
        expect(
          find.descendant(of: find.byType(ChatComposer), matching: _dog),
          findsOneWidget,
        );
        for (final keyboard in [false, true]) {
          if (keyboard) {
            await tester.tap(find.byType(EditableText));
            tester.view.viewInsets = const FakeViewPadding(bottom: 300 * 3);
            await tester.pumpAndSettle();
          }
          final dog = tester.getRect(_dog);
          final input = tester.getRect(
            find.byKey(const ValueKey('chat-input')),
          );
          expect(dog.bottom, greaterThan(input.top));
          expect(dog.top + dog.height * 0.68, lessThan(input.top));
          expect(dog.bottom - input.top, closeTo(dog.height * 0.3, 1));
          expect(dog.left, greaterThanOrEqualTo(input.left));
          expect(dog.right, lessThanOrEqualTo(input.right));
          expect(tester.takeException(), isNull);
        }
        await tester.enterText(find.byType(EditableText), 'hello');
        await tester.pump();
        await tester.tap(find.bySemanticsLabel(t.chat.send));
        await tester.pump();
        await tester.pumpAndSettle();
        expect(_dog, findsNothing);
      });
    }
  }
}
