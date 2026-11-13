import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:selfbox/core/router/app_dock_tabs.dart';
import 'package:selfbox/core/testing/app_widget_tester.dart';
import 'package:selfbox/core/widgets/app_artwork.dart';

Finder get _dog => find.byWidgetPredicate(
  (w) => w is AppArtwork && w.artwork == BrandArt.welcome,
);
Finder get _tabs => find.byKey(const ValueKey('composer-tabs-reveal'));

void main() {
  for (final brightness in Brightness.values) {
    for (final width in [280.0, 390.0]) {
      testWidgets(
        'mascot and tabs interpolate and reverse in $brightness/$width',
        (tester) async {
          tester.platformDispatcher.platformBrightnessTestValue = brightness;
          addTearDown(
            tester.platformDispatcher.clearPlatformBrightnessTestValue,
          );
          await tester.pumpApp();
          tester.view.physicalSize = Size(width * 3, 844 * 3);
          await tester.pumpAndSettle();
          final original = tester.getSize(_dog).width;
          final tabsHeight = tester.getSize(find.byType(AppDockTabs)).height;
          final image = tester
              .widget<Image>(
                find.descendant(of: _dog, matching: find.byType(Image)),
              )
              .image;
          await tester.tap(find.byType(EditableText));
          tester.view.viewInsets = const FakeViewPadding(bottom: 900);
          await tester.pump();
          expect(tester.getSize(_dog).width, original);
          expect(find.byType(AppDockTabs), findsOneWidget);
          await tester.pump(const Duration(milliseconds: 100));
          final middle = tester.getSize(_dog).width;
          expect(middle, lessThan(original));
          expect(middle, greaterThan(96));
          final dog = tester.getRect(_dog);
          final input = tester.getRect(
            find.byKey(const ValueKey('chat-input')),
          );
          expect(dog.bottom - input.top, closeTo(dog.height * 0.3, 0.01));
          expect(dog.left, greaterThanOrEqualTo(input.left));
          expect(dog.right, lessThanOrEqualTo(input.right));
          expect(tester.getSize(_tabs).height, inExclusiveRange(0, tabsHeight));
          final opacity = tester.widget<Opacity>(
            find.descendant(of: _tabs, matching: find.byType(Opacity)).first,
          );
          expect(opacity.opacity, inExclusiveRange(0, 1));
          final ignore = tester.widget<IgnorePointer>(
            find
                .ancestor(of: _tabs, matching: find.byType(IgnorePointer))
                .first,
          );
          expect(ignore.ignoring, isTrue);
          expect(
            tester
                .widget<Image>(
                  find.descendant(of: _dog, matching: find.byType(Image)),
                )
                .image,
            image,
          );
          final field = tester.widget<EditableText>(find.byType(EditableText));
          field.focusNode.unfocus();
          await tester.pump();
          await tester.pump();
          expect(tester.getSize(_dog).width, closeTo(middle, 0.01));
          await tester.pump(const Duration(milliseconds: 100));
          expect(tester.getSize(_dog).width, greaterThan(middle));
          await tester.pumpAndSettle();
          expect(tester.getSize(_dog).width, original);
          expect(tester.getSize(_tabs).height, tabsHeight);
          field.focusNode.requestFocus();
          await tester.pumpAndSettle();
          expect(tester.getSize(_dog).width, 96);
          expect(find.byType(AppDockTabs), findsNothing);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
  testWidgets('reduced motion snaps to final keyboard layout', (tester) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await tester.pumpApp();
    await tester.tap(find.byType(EditableText));
    tester.view.viewInsets = const FakeViewPadding(bottom: 900);
    await tester.pump();
    await tester.pump();
    expect(tester.getSize(_dog).width, 96);
    expect(find.byType(AppDockTabs), findsNothing);
    tester.widget<EditableText>(find.byType(EditableText)).focusNode.unfocus();
    await tester.pump();
    await tester.pump();
    expect(tester.getSize(_dog).width, 144);
    expect(find.byType(AppDockTabs), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
