import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../../../../core/theme/app_glass_theme.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../providers/composer_controller.dart';
import 'chat_composer_controls.dart';
import 'chat_composer_keyboard_transition.dart';

/// Attachment moves between the shared input and a separate keyboard button.
class ChatComposerAttachment extends ConsumerWidget {
  const ChatComposerAttachment({
    required this.external,
    required this.keyboardOpen,
    super.key,
  });

  final bool external;
  final bool keyboardOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ChatComposerKeyboardTransition.progressOf(context);
    final visible = external ? progress : 1 - progress;
    if (visible == 0) return const SizedBox.shrink();
    final button = ChatAttachButton(
      onTap: ref.read(composerControllerProvider.notifier).pickImage,
    );
    final glass = context.glass;
    return IgnorePointer(
      ignoring: keyboardOpen != external,
      child: ExcludeSemantics(
        excluding: keyboardOpen != external,
        child: ClipRect(
          child: Align(
            widthFactor: visible,
            alignment: Alignment.centerLeft,
            child: Opacity(
              opacity: visible,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (external)
                    GlassContainer(
                      quality: GlassQuality.standard,
                      useOwnLayer: true,
                      settings: LiquidGlassSettings(
                        blur: glass.chromeBlur,
                        glassColor: glass.chromeTint,
                      ),
                      shape: const LiquidRoundedSuperellipse(
                        borderRadius: AppRadius.pill,
                      ),
                      child: button,
                    )
                  else
                    button,
                  const Gap(AppSpacing.xs),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
