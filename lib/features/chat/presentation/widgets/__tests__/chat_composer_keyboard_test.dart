import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:selfbox/core/testing/app_widget_tester.dart';
import 'package:selfbox/core/theme/app_glass_theme.dart';
import 'package:selfbox/core/theme/app_spacing.dart';
import 'package:selfbox/features/chat/presentation/providers/composer_controller.dart';
import 'package:selfbox/features/chat/presentation/widgets/chat_composer.dart';
import 'package:selfbox/features/chat/presentation/widgets/chat_composer_controls.dart';
import 'package:selfbox/features/chat/presentation/widgets/chat_composer_input_row.dart';
import 'package:selfbox/gen/i18n/strings.g.dart';

class _CountingPicker extends Fake implements ImagePicker {
  var calls = 0;

  @override
  Future<List<XFile>> pickMultiImage({
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    int? limit,
    bool requestFullMetadata = true,
  }) async {
    calls++;
    return const [];
  }
}

void main() {
  testWidgets(
    'composer input row uses balanced insets across keyboard states',
    (tester) async {
      await tester.pumpApp();
      for (final keyboard in [false, true]) {
        if (keyboard) {
          tester.view.viewInsets = const FakeViewPadding(bottom: 900);
          await tester.showKeyboard(find.byType(EditableText));
          await tester.pumpAndSettle();
        }
        final surface = tester.getRect(
          find.byKey(const ValueKey('chat-input')),
        );
        final row = tester.getRect(find.byType(ChatComposerInputRow));
        final send = tester.getRect(find.byType(ChatSendButton));
        final circle = tester.getRect(
          find.descendant(
            of: find.byType(ChatSendButton),
            matching: find.byType(AnimatedContainer),
          ),
        );
        expect(
          send.right,
          closeTo(surface.right - (keyboard ? 0 : AppSpacing.xs), 0.01),
        );
        expect(
          send.top - surface.top,
          closeTo(keyboard ? 0 : AppSpacing.xs, 0.01),
        );
        expect(
          surface.right - circle.right,
          closeTo(circle.top - surface.top, 0.01),
        );
        expect(row.height, keyboard ? AppSizes.minTouchTarget : 64);
      }
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'multiline editing keeps internal breathing room with either keyboard state',
    (tester) async {
      await tester.pumpApp();
      await tester.enterText(
        find.byType(EditableText),
        'one\ntwo\nthree\nfour\nfive\nsix',
      );
      for (final keyboard in [0.0, 900.0]) {
        tester.view.viewInsets = FakeViewPadding(bottom: keyboard);
        await tester.pumpAndSettle();
        final input = tester.getRect(find.byKey(const ValueKey('chat-input')));
        final editor = tester.getRect(find.byType(EditableText));
        final field = tester.getRect(find.byType(CupertinoTextField));
        final row = tester.getRect(find.byType(ChatComposerInputRow));
        expect(editor.top - field.top, greaterThanOrEqualTo(AppSpacing.sm));
        expect(
          field.bottom - editor.bottom,
          greaterThanOrEqualTo(AppSpacing.sm),
        );
        expect(
          row.height - field.height,
          closeTo(keyboard == 0 ? AppSpacing.xs * 2 : 0, 0.01),
        );
        expect(input.height, greaterThanOrEqualTo(row.height));
        final send = tester.getRect(find.byType(ChatSendButton));
        final attach = tester.getRect(
          find.byType(ChatAttachButton).hitTestable(),
        );
        expect(send.bottom, closeTo(field.bottom, 0.01));
        expect(attach.bottom, closeTo(send.bottom, 0.01));
        expect(tester.takeException(), isNull);
      }
    },
  );
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
    final attachSurface = tester.widget<GlassContainer>(
      find
          .ancestor(
            of: find.byType(ChatAttachButton),
            matching: find.byType(GlassContainer),
          )
          .first,
    );
    expect(attachSurface.quality, GlassQuality.standard);
    final inputSurface = tester.widget<GlassContainer>(
      find.descendant(
        of: find.byKey(const ValueKey('chat-input')),
        matching: find.byType(GlassContainer),
      ),
    );
    expect(attachSurface.settings?.blur, inputSurface.settings?.blur);
    expect(
      attachSurface.settings?.glassColor,
      inputSurface.settings?.glassColor,
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
    final surface = tester.getRect(find.byKey(const ValueKey('chat-input')));
    expect(surface.right, kPhoneViewport.width - AppSpacing.md);
    expect(surface.right - send.right, 0);
  });

  testWidgets('keyboard single-line field matches the attach control height', (
    tester,
  ) async {
    await tester.pumpApp();
    final editable = find.byType(EditableText);
    await tester.enterText(editable, 'single line');
    tester.view.viewInsets = const FakeViewPadding(bottom: 900);
    await tester.pumpAndSettle();
    final field = tester.getRect(find.byType(CupertinoTextField));
    final attach = tester.getRect(find.byType(ChatAttachButton));
    expect(field.height, closeTo(attach.height, 1));
    expect(field.height, AppSizes.minTouchTarget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('soft-wrapped text receives internal vertical spacing', (
    tester,
  ) async {
    await tester.pumpApp();
    tester.view.physicalSize = const Size(320 * 3, 640 * 3);
    final editable = find.byType(EditableText);
    await tester.enterText(
      editable,
      'A long line that wraps across the input width',
    );
    await tester.pumpAndSettle();
    final field = tester.getRect(find.byType(CupertinoTextField));
    final editor = tester.getRect(editable);
    expect(editor.top - field.top, greaterThanOrEqualTo(AppSpacing.sm));
    expect(field.bottom - editor.bottom, greaterThanOrEqualTo(AppSpacing.sm));
    expect(tester.takeException(), isNull);
  });

  testWidgets('tapping empty input edge requests focus', (tester) async {
    await tester.pumpApp();
    final editable = find.byType(EditableText);
    await tester.enterText(editable, 'draft');
    tester.view.viewInsets = const FakeViewPadding(bottom: 900);
    await tester.pumpAndSettle();
    final focusNode = tester.widget<EditableText>(editable).focusNode;
    focusNode.unfocus();
    await tester.pump();
    final field = tester.getRect(find.byKey(const ValueKey('chat-input')));
    await tester.tapAt(Offset(field.left + 2, field.center.dy));
    await tester.pump();
    expect(focusNode.hasFocus, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'keyboard attach opens the picker without first dismissing focus',
    (tester) async {
      final picker = _CountingPicker();
      await tester.pumpApp(
        overrides: [imagePickerProvider.overrideWithValue(picker)],
      );
      final editable = find.byType(EditableText);
      await tester.enterText(editable, 'draft');
      tester.view.viewInsets = const FakeViewPadding(bottom: 900);
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel(t.chat.attachImage));
      await tester.pump();
      expect(picker.calls, 1);
      expect(tester.widget<EditableText>(editable).focusNode.hasFocus, isTrue);
    },
  );

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
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 600));
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
}
