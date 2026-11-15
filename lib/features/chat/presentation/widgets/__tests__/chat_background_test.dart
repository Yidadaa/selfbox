import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:selfbox/core/theme/app_effects.dart';
import 'package:selfbox/features/chat/presentation/providers/chat_scroll_controller.dart';
import 'package:selfbox/features/chat/presentation/widgets/chat_quote_button.dart';
import 'package:selfbox/gen/i18n/strings.g.dart';

void registerTests({
  required Future<ProviderContainer> Function(WidgetTester) pumpChat,
  required Future<void> Function(WidgetTester, Widget) pumpPage,
}) {
  for (final animated in [false, true]) {
    testWidgets('background immediately stops scrolling animated=$animated', (
      tester,
    ) async {
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      addTearDown(
        () => tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        ),
      );
      final container = await pumpChat(tester);
      final controller = container.read(chatScrollControllerProvider);
      controller.jumpTo(400);
      if (animated) {
        unawaited(
          controller.animateTo(
            0,
            duration: const Duration(seconds: 1),
            curve: Curves.linear,
          ),
        );
      } else {
        (controller.position as ScrollPositionWithSingleContext).goBallistic(
          1500,
        );
      }
      await tester.pump(const Duration(milliseconds: 50));
      expect(controller.position.isScrollingNotifier.value, isTrue);
      final offset = controller.offset;
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      expect(controller.position.isScrollingNotifier.value, isFalse);
      expect(controller.offset, offset);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump(const Duration(seconds: 1));
      expect(controller.offset, offset);
      controller.jumpTo(200);
      expect(controller.offset, 200);
    });
  }
  for (final quality in GlassQuality.values) {
    testWidgets('bottom button is circular icon with $quality effects', (
      tester,
    ) async {
      var taps = 0;
      await pumpPage(
        tester,
        AppEffects(
          quality: quality,
          animationsEnabled: true,
          child: Center(child: ChatScrollToBottomButton(onTap: () => taps++)),
        ),
      );
      final button = find.byType(ChatScrollToBottomButton);
      final size = tester.getSize(button);
      expect(size.width, size.height);
      expect(size.width, greaterThanOrEqualTo(48));
      expect(
        find.descendant(of: button, matching: find.byType(Text)),
        findsNothing,
      );
      final glass = tester.widget<GlassContainer>(
        find.descendant(of: button, matching: find.byType(GlassContainer)),
      );
      expect(glass.quality, quality);
      expect(glass.shape, isA<LiquidOval>());
      await tester.tap(find.bySemanticsLabel(t.chat.scrollToBottom));
      expect(taps, 1);
    });
  }
}
