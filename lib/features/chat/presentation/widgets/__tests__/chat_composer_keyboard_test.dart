import 'package:flutter/material.dart';
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
    'multiline editing keeps vertical breathing room with either keyboard state',
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
        expect(editor.top - input.top, greaterThanOrEqualTo(AppSpacing.sm));
        final row = tester.getRect(find.byType(ChatComposerInputRow));
        expect(row.bottom - editor.bottom, greaterThanOrEqualTo(AppSpacing.sm));
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
    expect(surface.right - send.right, AppSpacing.composerVertical);
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
