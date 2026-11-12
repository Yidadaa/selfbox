import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:selfbox/core/theme/app_motion.dart';
import 'package:selfbox/features/chat/presentation/widgets/outgoing_message_entrance.dart';

void main() {
  testWidgets('entry expands, slides, fades and finishes once', (tester) async {
    var completed = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: OutgoingMessageEntrance(
            onComplete: () => completed++,
            child: const SizedBox(height: 80, width: 200),
          ),
        ),
      ),
    );

    final entrance = find.byType(OutgoingMessageEntrance);
    final size = find.descendant(
      of: entrance,
      matching: find.byType(SizeTransition),
    );
    final slide = find.descendant(
      of: entrance,
      matching: find.byType(SlideTransition),
    );
    final fade = find.descendant(
      of: entrance,
      matching: find.byType(FadeTransition),
    );
    expect(tester.widget<SizeTransition>(size).sizeFactor.value, 0);
    expect(
      tester.widget<SizeTransition>(size).alignment,
      Alignment.bottomCenter,
    );
    expect(
      tester.widget<SlideTransition>(slide).position.value,
      AppMotion.messageSendOffset,
    );
    expect(tester.widget<FadeTransition>(fade).opacity.value, lessThan(1));

    await tester.pump(AppMotion.messageSend ~/ 2);
    final midpoint = tester.widget<SizeTransition>(size).sizeFactor.value;
    expect(midpoint, inInclusiveRange(0.01, 0.99));
    expect(completed, 0);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: OutgoingMessageEntrance(
            onComplete: () => completed++,
            child: const SizedBox(height: 80, width: 200),
          ),
        ),
      ),
    );
    expect(tester.widget<SizeTransition>(size).sizeFactor.value, midpoint);

    await tester.pump(AppMotion.messageSend);
    expect(tester.widget<SizeTransition>(size).sizeFactor.value, 1);
    expect(tester.widget<SlideTransition>(slide).position.value, Offset.zero);
    expect(completed, 1);
  });
}
