import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:selfbox/core/error/app_failure.dart';
import 'package:selfbox/core/router/app_dock_tabs.dart';
import 'package:selfbox/core/router/app_router.dart';
import 'package:selfbox/core/theme/app_glass_theme.dart';
import 'package:selfbox/core/theme/app_motion.dart';
import 'package:selfbox/core/theme/app_spacing.dart';
import 'package:selfbox/core/theme/sdk_material.dart';
import 'package:selfbox/core/widgets/ai_composer_glow.dart';
import 'package:selfbox/features/chat/domain/models/message.dart';
import 'package:selfbox/features/chat/presentation/providers/composer_controller.dart';
import 'package:selfbox/features/chat/presentation/widgets/chat_composer.dart';
import 'package:selfbox/features/chat/presentation/widgets/chat_composer_controls.dart';
import 'package:selfbox/features/chat/presentation/widgets/message_bubble.dart';
import 'package:selfbox/gen/i18n/strings.g.dart';

import '../../../../support/app_widget_tester.dart';
import '../../../../support/fake_message_repository.dart';

class _AttachedDraft extends ComposerController {
  @override
  ComposerState build() =>
      const ComposerState(attachments: ['../unavailable.png']);
}

void main() {
  testWidgets(
    'small screen budgets attached multiline input through keyboard dismissal',
    (tester) async {
      await tester.pumpApp(
        overrides: [
          composerControllerProvider.overrideWith(_AttachedDraft.new),
        ],
      );
      tester.view.physicalSize = const Size(320 * 3, 640 * 3);
      tester.view.viewInsets = const FakeViewPadding(bottom: 300 * 3);
      await tester.enterText(
        find.byType(EditableText),
        'one\ntwo\nthree\nfour\nfive\nsix',
      );
      await tester.pumpAndSettle();
      expect(
        tester.getTopLeft(find.byType(ChatComposer)).dy,
        greaterThanOrEqualTo(47 + AppSizes.appBarHeight),
      );
      expect(
        tester.getBottomLeft(find.byType(ChatComposer)).dy,
        closeTo(640 - 300 - AppSpacing.xs, 1),
      );
      tester
          .widget<EditableText>(find.byType(EditableText))
          .focusNode
          .unfocus();
      await tester.pump();
      await tester.pump(AppMotion.fast);
      expect(find.byType(AppDockTabs), findsOneWidget);
      expect(
        tester.getTopLeft(find.byType(ChatComposer)).dy,
        greaterThanOrEqualTo(47 + AppSizes.appBarHeight),
      );
      expect(
        tester.getBottomLeft(find.byType(ChatComposer)).dy,
        closeTo(640 - 300 - AppSpacing.xs, 1),
      );
      await tester.tap(find.bySemanticsLabel(t.chat.removeImage));
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel(t.chat.removeImage), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('blank input cannot send and a failed send preserves the draft', (
    tester,
  ) async {
    final messages = FakeMessageRepository()
      ..failNextAdd = const Some(AppFailure.database(message: 'disk full'));
    await tester.pumpApp(messages: messages);
    await tester.tap(find.bySemanticsLabel(t.chat.send));
    expect(messages.added, isEmpty);
    await tester.enterText(find.byType(EditableText), 'keep on failure');
    await tester.pump();
    await tester.tap(find.bySemanticsLabel(t.chat.send));
    await tester.pumpAndSettle();
    expect(
      tester.widget<EditableText>(find.byType(EditableText)).controller.text,
      'keep on failure',
    );
    await tester.tap(find.bySemanticsLabel(t.chat.send));
    await tester.pumpAndSettle();
    expect(
      tester.widget<EditableText>(find.byType(EditableText)).controller.text,
      isEmpty,
    );
    expect(find.byType(MessageBubble), findsOneWidget);
  });

  for (final brightness in Brightness.values) {
    testWidgets('latest message clears a growing dock in ${brightness.name}', (
      tester,
    ) async {
      tester.platformDispatcher.platformBrightnessTestValue = brightness;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
      await tester.pumpApp(
        messages: FakeMessageRepository(
          seed: [
            Message(
              id: 1,
              createdAt: kTestNow,
              author: MessageAuthor.me,
              text: 'latest note',
            ),
          ],
        ),
      );
      await tester.enterText(
        find.byType(EditableText),
        'one\ntwo\nthree\nfour\nfive\nsix',
      );
      tester.view.viewInsets = const FakeViewPadding(bottom: 900);
      await tester.pumpAndSettle();
      expect(
        tester.getBottomLeft(find.byType(MessageBubble)).dy,
        lessThan(tester.getTopLeft(find.byType(ChatComposer)).dy),
      );
      expect(
        tester.getTopLeft(find.byType(ChatComposer)).dy,
        greaterThan(47 + AppSizes.appBarHeight),
      );
      expect(
        Theme.of(tester.element(find.byType(ChatComposer))).brightness,
        brightness,
      );
      await tester.tap(find.text('latest note'));
      await tester.pump();
      expect(
        tester
            .widget<EditableText>(find.byType(EditableText))
            .focusNode
            .hasFocus,
        isFalse,
      );
      expect(tester.takeException(), isNull);
    });
  }

  for (final brightness in Brightness.values) {
    testWidgets(
      'input dock uses themed chrome and aligned controls in ${brightness.name}',
      (tester) async {
        tester.platformDispatcher.platformBrightnessTestValue = brightness;
        addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
        await tester.pumpApp();
        final field = tester.widget<GlassContainer>(
          find.descendant(
            of: find.byKey(const ValueKey('chat-input')),
            matching: find.byType(GlassContainer),
          ),
        );
        expect(field.useOwnLayer, isTrue);
        final glass = AppGlassTheme.of(brightness);
        expect(field.settings?.blur, glass.chromeBlur);
        expect(field.settings?.glassColor, glass.chromeTint);
        final dock = tester.getRect(find.byType(ChatComposer));
        expect(
          tester.getSize(find.byKey(const ValueKey('chat-input'))).height,
          lessThan(140),
        );
        final tabs = tester.getRect(find.byType(AppDockTabs));
        expect(dock.left, AppSpacing.md);
        expect(dock.right, kPhoneViewport.width - AppSpacing.md);
        expect(dock.bottom, kPhoneViewport.height - 34 - AppSpacing.md);
        expect(tabs.left, dock.left);
        expect(tabs.right, dock.right);
        expect(find.byType(AiComposerGlow), findsOneWidget);
        expect(
          find.descendant(
            of: find.byKey(const ValueKey('chat-input')),
            matching: find.text(t.tabs.memory),
          ),
          findsOneWidget,
        );
      },
    );
  }

  for (final locale in AppLocale.values) {
    testWidgets('narrow viewport and multiline draft work in ${locale.name}', (
      tester,
    ) async {
      final container = await tester.pumpApp(locale: locale);
      tester.view.physicalSize = const Size(320 * 3, 640 * 3);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(EditableText),
        'one\ntwo\nthree\nfour\nfive\nsix',
      );
      await tester.pumpAndSettle();
      expect(
        tester.getBottomLeft(find.byType(ChatComposer)).dy,
        lessThanOrEqualTo(640 - 34),
      );
      expect(
        tester.getSize(
          find.descendant(
            of: find.byType(ChatSendButton),
            matching: find.byType(HugeIcon),
          ),
        ),
        const Size.square(AppSizes.iconSm),
      );
      container.read(appRouterProvider).go('/memory');
      await tester.pumpAndSettle();
      container.read(appRouterProvider).go('/chat');
      await tester.pumpAndSettle();
      expect(
        tester.widget<EditableText>(find.byType(EditableText)).controller.text,
        'one\ntwo\nthree\nfour\nfive\nsix',
      );
      expect(tester.takeException(), isNull);
    });
  }
}
