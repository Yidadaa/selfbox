import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:selfbox/core/theme/app_glass_theme.dart';
import 'package:selfbox/core/theme/sdk_material.dart';
import 'package:selfbox/core/widgets/app_icon.dart';
import 'package:selfbox/features/chat/presentation/providers/chat_scroll_controller.dart';
import 'package:selfbox/features/chat/presentation/widgets/pinned_messages_panel.dart';
import 'package:selfbox/features/settings/domain/models/app_preferences.dart';

import '../../../../support/app_widget_tester.dart';
import '../../../../support/fake_message_repository.dart';
import '../pages/chat_page_test_support.dart';

void main() {
  for (final theme in [AppThemeChoice.dark, AppThemeChoice.light]) {
    for (final quality in AppRenderQuality.values) {
      testWidgets('pin material and reduced motion $theme $quality', (
        tester,
      ) async {
        final repo = FakeMessageRepository(seed: [testMessage(1, 'pinned')]);
        await repo.setPinned(1, pinned: true).run();
        await tester.pumpApp(
          messages: repo,
          initialPreferences: AppPreferences(
            theme: theme,
            renderQuality: quality,
            animationsEnabled: false,
          ),
        );
        final bubble = find.byKey(const ValueKey('pinned-bubble'));
        final expected = switch (quality) {
          AppRenderQuality.minimal => GlassQuality.minimal,
          AppRenderQuality.standard => GlassQuality.standard,
          AppRenderQuality.premium => GlassQuality.premium,
        };
        expect(tester.widget<GlassContainer>(bubble).quality, expected);
        final pin = tester.widget<AppIcon>(
          find.descendant(of: bubble, matching: find.byType(AppIcon)),
        );
        expect(
          pin.color,
          (theme == AppThemeChoice.light
                  ? AppGlassTheme.light
                  : AppGlassTheme.dark)
              .foregroundMuted,
        );
        expect(tester.getSize(bubble).height, greaterThanOrEqualTo(48));
        await tester.tap(bubble);
        await tester.pumpAndSettle();
        final panel = find.byKey(const ValueKey('pinned-panel'));
        final fade = find.byKey(const ValueKey('pinned-message-edge-fade'));
        expect(fade, findsOneWidget);
        expect(tester.getRect(fade).top, tester.getRect(panel).top);
        expect(tester.getRect(fade).bottom, tester.getRect(panel).bottom);
        for (final key in ['clear-pins', 'close-pins']) {
          expect(
            tester
                .getRect(fade)
                .overlaps(tester.getRect(find.byKey(ValueKey(key)))),
            true,
          );
        }
        expect(
          find.descendant(
            of: fade,
            matching: find.byKey(const ValueKey('close-pins')),
          ),
          findsNothing,
        );
        expect(
          find.descendant(
            of: fade,
            matching: find.byKey(const ValueKey('clear-pins')),
          ),
          findsNothing,
        );
        final shape = tester.widget<GlassContainer>(panel).shape;
        if (theme == AppThemeChoice.light) {
          final color = tester.widget<GlassContainer>(panel).color;
          expect(color, isNot(AppGlassTheme.light.bubbleOther));
          expect(color?.computeLuminance(), lessThan(0.9));
          final surface = tester.widget<DecoratedBox>(
            find.byKey(const ValueKey('pinned-panel-background')),
          );
          final gradient = (surface.decoration as ShapeDecoration).gradient;
          expect(gradient, isA<LinearGradient>());
          expect(gradient?.colors.every((color) => color.a == 1), true);
          expect(
            gradient?.colors.first.computeLuminance(),
            greaterThan(gradient?.colors.last.computeLuminance() ?? 1),
          );
        }
        final surfaces = tester.widgetList<DecoratedBox>(
          find.descendant(of: panel, matching: find.byType(DecoratedBox)),
        );
        expect(
          surfaces.any(
            (surface) => switch (surface.decoration) {
              ShapeDecoration(:final color, shape: final border) =>
                border == shape && color?.a == 1,
              _ => false,
            },
          ),
          true,
        );
        for (final button in tester.widgetList<GlassIconButton>(
          find.descendant(of: panel, matching: find.byType(GlassIconButton)),
        )) {
          expect(button.quality, GlassQuality.minimal);
        }
        await tester.tap(find.byKey(const ValueKey('close-pins')));
        await tester.pumpAndSettle();
        expect(panel, findsNothing);
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets(
    'panel opens and closes immediately; both lists remain interactive',
    (tester) async {
      final repo = FakeMessageRepository(
        seed: List.generate(40, (i) => testMessage(i + 1, 'note $i')),
      );
      for (var id = 1; id <= 40; id++) {
        await repo.setPinned(id, pinned: true).run();
      }
      final container = await tester.pumpApp(messages: repo);
      await tester.tap(find.byKey(const ValueKey('pinned-bubble')));
      await tester.pump();
      final before = tester.widget<PinnedMessagesPanel>(
        find.byType(PinnedMessagesPanel),
      );
      final size = tester.getSize(find.byKey(const ValueKey('pinned-panel')));
      await tester.pump(const Duration(milliseconds: 40));
      expect(
        identical(before, tester.widget(find.byType(PinnedMessagesPanel))),
        true,
      );
      expect(tester.getSize(find.byKey(const ValueKey('pinned-panel'))), size);
      before.onClose();
      await tester.pump();
      expect(find.byType(PinnedMessagesPanel), findsNothing);
      expect(find.byKey(const ValueKey('pinned-bubble')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('pinned-bubble')));
      await tester.pumpAndSettle();
      final pinnedList = find.byKey(
        const PageStorageKey('pinned-message-list'),
      );
      final pinnedScroll = tester.state<ScrollableState>(
        find.descendant(of: pinnedList, matching: find.byType(Scrollable)),
      );
      final pinnedOffset = pinnedScroll.position.pixels;
      final bounds = tester.getRect(pinnedList);
      await tester.dragFrom(
        bounds.topLeft + const Offset(32, 32),
        const Offset(0, 100),
      );
      await tester.pumpAndSettle();
      expect(pinnedScroll.position.pixels, greaterThan(pinnedOffset));
      final controller = container.read(chatScrollControllerProvider);
      final previous = controller.offset;
      await tester.dragFrom(const Offset(190, 605), const Offset(0, 200));
      await tester.pumpAndSettle();
      expect(controller.offset, greaterThan(previous));
      expect(find.byKey(const ValueKey('pinned-panel')), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Search messages'));
      await tester.pumpAndSettle();
      expect(find.text('Search your notes'), findsOneWidget);
    },
  );
}
