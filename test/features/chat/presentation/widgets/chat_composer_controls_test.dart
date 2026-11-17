import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:selfbox/core/theme/app_effects.dart';
import 'package:selfbox/core/theme/app_glass_theme.dart';
import 'package:selfbox/core/theme/app_icons.dart';
import 'package:selfbox/core/theme/app_radius.dart';
import 'package:selfbox/core/widgets/app_icon.dart';
import 'package:selfbox/core/widgets/pressable.dart';
import 'package:selfbox/features/chat/presentation/widgets/chat_composer_controls.dart';

import '../../../../support/app_widget_tester.dart';

void main() {
  for (final brightness in Brightness.values) {
    for (final quality in GlassQuality.values) {
      testWidgets('attachment controls retain geometry and removal '
          'in $brightness $quality', (tester) async {
        final removed = <String>[];
        await tester.pumpPage(
          AppEffects(
            quality: quality,
            animationsEnabled: false,
            child: Scaffold(
              body: ChatAttachmentStrip(
                paths: const ['../first.png', '../second.png'],
                onRemove: removed.add,
              ),
            ),
          ),
          brightness: brightness,
        );
        final strip = find.byType(ChatAttachmentStrip);
        final buttons = find.descendant(
          of: strip,
          matching: find.byType(Pressable),
        );
        final surfaces = find.descendant(
          of: strip,
          matching: find.byType(GlassContainer),
        );
        expect(surfaces, findsNWidgets(2));
        final photos = find.byKey(
          const ValueKey('attachment-photo-../first.png'),
        );
        final photo = tester.widget<ClipPath>(photos);
        expect(
          (photo.clipper as ShapeBorderClipper).shape,
          const LiquidRoundedSuperellipse(borderRadius: AppRadius.sm),
        );
        expect(tester.getSize(photos), const Size.square(64));
        expect(tester.getSize(buttons.first), const Size.square(48));
        expect(tester.getSize(surfaces.first), const Size.square(24));
        final photoRect = tester.getRect(photos);
        final buttonRect = tester.getRect(surfaces.first);
        expect(buttonRect.top - photoRect.top, 6);
        expect(photoRect.right - buttonRect.right, 6);
        final surface = tester.widget<GlassContainer>(surfaces.first);
        expect(surface.shape, const LiquidOval());
        expect(surface.useOwnLayer, isTrue);
        expect(
          surface.quality,
          quality == GlassQuality.minimal
              ? GlassQuality.minimal
              : GlassQuality.standard,
        );
        expect(surface.settings, isNull);
        final icon = tester.widget<AppIcon>(
          find.descendant(of: surfaces.first, matching: find.byType(AppIcon)),
        );
        expect(icon.icon, AppIcons.close);
        expect(icon.size, 12);
        expect(icon.color, AppGlassTheme.of(brightness).foregroundMuted);
        await tester.tapAt(
          tester.getBottomLeft(buttons.first) + const Offset(1, -1),
        );
        await tester.pumpAndSettle();
        expect(removed, ['../first.png']);
        await tester.tap(surfaces.last);
        await tester.pumpAndSettle();
        expect(removed, ['../first.png', '../second.png']);
        expect(tester.takeException(), isNull);
      });
    }
  }
}
