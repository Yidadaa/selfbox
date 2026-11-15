import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:selfbox/core/error/app_failure.dart';
import 'package:selfbox/core/router/app_router.dart';
import 'package:selfbox/core/testing/app_widget_tester.dart';
import 'package:selfbox/core/testing/fake_message_repository.dart';
import 'package:selfbox/core/theme/app_spacing.dart';
import 'package:selfbox/features/chat/domain/models/message.dart';
import 'package:selfbox/features/chat/presentation/providers/composer_controller.dart';
import 'package:selfbox/features/chat/presentation/providers/message_lookup.dart';
import 'package:selfbox/features/chat/presentation/widgets/chat_composer.dart';
import 'package:selfbox/features/chat/presentation/widgets/message_text_content.dart';
import 'package:selfbox/features/settings/domain/models/app_preferences.dart';
import 'package:selfbox/gen/i18n/strings.g.dart';
import 'package:skeletonizer/skeletonizer.dart';

import 'chat_page_test_support.dart';

void main() {
  for (final expanded in [true, false]) {
    testWidgets(
      'message page expanded=$expanded loads, reports failure and retries',
      (tester) async {
        final ready = Completer<void>();
        var failing = true;
        final message = testMessage(4, 'recovered original');
        final container = await tester.pumpApp(
          overrides: [
            messageByIdProvider(4).overrideWith((ref) async {
              if (failing) {
                await ready.future;
                return const Left(AppFailure.database(message: 'read failed'));
              }
              return Right(Some(message));
            }),
          ],
        );
        container
            .read(appRouterProvider)
            .go(expanded ? '/chat/message/4' : '/chat/at/4');
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        expect(
          find.byWidgetPredicate((widget) => widget is Skeletonizer),
          findsWidgets,
        );
        ready.complete();
        await tester.pumpAndSettle();
        expect(find.text(t.common.loadFailed), findsOneWidget);
        failing = false;
        await tester.tap(find.text(t.common.retry));
        await tester.pumpAndSettle();
        expect(find.text('recovered original'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
  for (final animate in [true, false]) {
    testWidgets(
      'long reply opens without transition and doubles reading insets with animations=$animate',
      (tester) async {
        final message = testMessage(
          2,
          '${List.filled(80, 'long paragraph').join('\n\n')}\n\nFINAL MARKER',
          author: MessageAuthor.ai,
        );
        final container = await tester.pumpApp(
          messages: FakeMessageRepository(
            seed: [testMessage(1, 'question'), message],
          ),
          initialPreferences: AppPreferences(animationsEnabled: animate),
        );
        container.read(composerControllerProvider.notifier).toggleAiMode();
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('expand-message')));
        await tester.pump();
        await tester.pump();
        expect(
          container.read(appRouterProvider).state.matchedLocation,
          '/chat/message/2',
        );
        expect(find.byType(ChatComposer), findsNothing);
        final list = find.byKey(const ValueKey('full-message-2'));
        final route = ModalRoute.of(tester.element(list));
        expect(route?.transitionDuration, Duration.zero);
        expect(route?.reverseTransitionDuration, Duration.zero);
        final insets = tester.widget<ListView>(list).padding as EdgeInsets;
        final safe = MediaQuery.paddingOf(tester.element(list));
        expect(insets.left, 32);
        expect(insets.right, 32);
        expect(insets.top, safe.top + AppSizes.appBarHeight + 32);
        expect(insets.bottom, safe.bottom + 32);
        final body = tester.getRect(
          find.descendant(of: list, matching: find.byType(MessageTextContent)),
        );
        expect(body.left, 32);
        expect(body.right, kPhoneViewport.width - 32);
        await tester.drag(list, const Offset(0, -10000));
        await tester.pumpAndSettle();
        expect(
          find.text('FINAL MARKER', findRichText: true).hitTestable(),
          findsOneWidget,
        );
        await tester.tap(find.bySemanticsLabel(t.common.close));
        await tester.pump();
        await tester.pump();
        expect(
          container.read(appRouterProvider).state.matchedLocation,
          '/chat',
        );
        expect(find.byKey(const ValueKey('expand-message')), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('deep link loads by ID and missing ID has a readable state', (
    tester,
  ) async {
    final container = await tester.pumpApp(
      messages: FakeMessageRepository(seed: [testMessage(4, 'stored body')]),
    );
    final router = container.read(appRouterProvider);
    router.go('/chat/message/4');
    await tester.pumpAndSettle();
    expect(find.text('stored body'), findsOneWidget);
    router.go('/chat/message/999');
    await tester.pumpAndSettle();
    expect(find.text(t.chat.messageMissing), findsOneWidget);
  });

  testWidgets(
    'select text on a collapsed reply opens the complete selectable body',
    (tester) async {
      final container = await tester.pumpApp(
        messages: FakeMessageRepository(
          seed: [
            testMessage(
              2,
              List.filled(80, 'paragraph').join('\n\n'),
              author: MessageAuthor.ai,
            ),
          ],
        ),
      );
      container.read(composerControllerProvider.notifier).toggleAiMode();
      await tester.pumpAndSettle();
      await tester.longPress(find.byKey(const ValueKey('expand-message')));
      await tester.pumpAndSettle();
      await tester.tap(find.text(t.common.selectText));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('full-message-2')), findsOneWidget);
      expect(find.byKey(const ValueKey('expand-message')), findsNothing);
    },
  );
}
