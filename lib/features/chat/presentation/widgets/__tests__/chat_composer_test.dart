import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:selfbox/core/error/app_failure.dart';
import 'package:selfbox/core/router/app_dock_tabs.dart';
import 'package:selfbox/core/router/app_router.dart';
import 'package:selfbox/core/testing/app_widget_tester.dart';
import 'package:selfbox/core/testing/fake_message_repository.dart';
import 'package:selfbox/core/theme/app_glass_theme.dart';
import 'package:selfbox/core/theme/app_spacing.dart';
import 'package:selfbox/features/chat/domain/models/message.dart';
import 'package:selfbox/features/chat/presentation/providers/composer_controller.dart';
import 'package:selfbox/features/chat/presentation/widgets/chat_composer.dart';
import 'package:selfbox/features/chat/presentation/widgets/chat_composer_controls.dart';
import 'package:selfbox/features/chat/presentation/widgets/message_bubble.dart';
import 'package:selfbox/gen/i18n/strings.g.dart';

class _AttachedDraft extends ComposerController {
  @override
  ComposerState build() =>
      const ComposerState(attachments: ['../unavailable.png']);
}

void main() {
  testWidgets(
    'small screen keeps an attached multiline draft below the header',
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
        expect(field.quality, GlassQuality.standard);
        expect(field.useOwnLayer, isTrue);
        final glass = AppGlassTheme.of(brightness);
        expect(field.settings?.blur, glass.chromeBlur);
        expect(field.settings?.glassColor, glass.chromeTint);
        final input = tester.getRect(find.byType(EditableText));
        final attach = tester.getRect(find.byType(ChatAttachButton));
        final send = tester.getRect(find.byType(ChatSendButton));
        expect(attach.center.dy, closeTo(input.center.dy, 1));
        expect(send.center.dy, closeTo(input.center.dy, 1));
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
        expect(
          tester
              .widget<GlassContainer>(
                find.descendant(
                  of: find.byType(ChatAiToggle),
                  matching: find.byType(GlassContainer),
                ),
              )
              .quality,
          GlassQuality.premium,
        );
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

  testWidgets('keyboard input controls stay centered and aligned to edges', (
    tester,
  ) async {
    await tester.pumpApp();
    await tester.enterText(find.byType(EditableText), 'Hello');
    tester.view.viewInsets = const FakeViewPadding(bottom: 900);
    await tester.pumpAndSettle();
    final input = tester.getRect(find.byType(EditableText));
    expect(
      tester.getSize(find.byKey(const ValueKey('chat-input'))).height,
      lessThan(80),
    );
    final attach = tester.getRect(find.byType(ChatAttachButton));
    final send = tester.getRect(find.byType(ChatSendButton));
    expect(
      tester
          .widget<GlassContainer>(
            find
                .ancestor(
                  of: find.byType(ChatAttachButton),
                  matching: find.byType(GlassContainer),
                )
                .first,
          )
          .quality,
      GlassQuality.standard,
    );
    expect(attach.center.dy, closeTo(input.center.dy, 1));
    expect(send.center.dy, closeTo(input.center.dy, 1));
    final sendCircle = tester.widget<AnimatedContainer>(
      find.descendant(
        of: find.byType(ChatSendButton),
        matching: find.byType(AnimatedContainer),
      ),
    );
    expect(
      (sendCircle.decoration! as BoxDecoration).color,
      AppGlassTheme.of(Brightness.dark).bubbleMine,
    );
    expect(attach.left, AppSpacing.md);
    expect(send.right, kPhoneViewport.width - AppSpacing.md);
  });

  testWidgets('keyboard hides tabs and preserves focus, selection and draft', (
    tester,
  ) async {
    await tester.pumpApp();
    final editable = find.byType(EditableText);
    await tester.enterText(editable, 'A draft worth keeping');
    final before = tester.widget<EditableText>(editable);
    before.controller.selection = const TextSelection.collapsed(offset: 7);
    tester.view.viewInsets = const FakeViewPadding(bottom: 900);
    await tester.pumpAndSettle();
    expect(find.text(t.tabs.memory), findsNothing);
    final after = tester.widget<EditableText>(editable);
    expect(after.focusNode.hasFocus, isTrue);
    expect(after.controller.text, 'A draft worth keeping');
    expect(after.controller.selection.baseOffset, 7);
    expect(
      tester.getBottomLeft(find.byType(ChatComposer)).dy,
      closeTo(kPhoneViewport.height - 300 - AppSpacing.xs, 1),
    );
    tester.view.viewInsets = const FakeViewPadding();
    await tester.pumpAndSettle();
    expect(find.text(t.tabs.memory), findsOneWidget);
    expect(
      tester.widget<EditableText>(editable).controller.text,
      'A draft worth keeping',
    );
    expect(tester.takeException(), isNull);
  });

  for (final draft in ['', 'A draft worth keeping']) {
    testWidgets('AI toggle keeps the keyboard for draft "$draft"', (
      tester,
    ) async {
      final container = await tester.pumpApp();
      final editable = find.byType(EditableText);
      await tester.enterText(editable, draft);
      final selection = draft.isEmpty ? 0 : 7;
      tester.widget<EditableText>(editable).controller.selection =
          TextSelection.collapsed(offset: selection);
      tester.view.viewInsets = const FakeViewPadding(bottom: 900);
      await tester.pumpAndSettle();

      for (final enabled in [true, false]) {
        await tester.tap(find.bySemanticsLabel(t.chat.aiMode));
        await tester.pumpAndSettle();
        expect(container.read(composerControllerProvider).aiMode, enabled);
        final field = tester.widget<EditableText>(editable);
        expect(field.focusNode.hasFocus, isTrue);
        expect(field.controller.text, draft);
        expect(field.controller.selection.baseOffset, selection);
        expect(find.text(t.tabs.memory), findsNothing);
        expect(
          tester.getBottomLeft(find.byType(ChatComposer)).dy,
          closeTo(kPhoneViewport.height - 300 - AppSpacing.xs, 1),
        );
      }
      expect(tester.takeException(), isNull);
    });
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
      for (final label in [t.chat.send, t.chat.attachImage, t.chat.aiMode]) {
        final size = tester.getSize(find.bySemanticsLabel(label).first);
        expect(size.width, greaterThanOrEqualTo(AppSizes.minTouchTarget));
        expect(size.height, greaterThanOrEqualTo(AppSizes.minTouchTarget));
      }
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
