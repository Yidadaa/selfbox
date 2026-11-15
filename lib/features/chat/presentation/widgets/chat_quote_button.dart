import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../../../../core/theme/app_effects.dart';
import '../../../../core/theme/app_glass_theme.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_icon.dart';
import '../../../../core/widgets/pressable.dart';
import '../../../../gen/i18n/strings.g.dart';
import 'message_quote_sheet.dart';

class ChatQuoteButton extends ConsumerWidget {
  const ChatQuoteButton({required this.count, super.key});
  final int count;

  @override
  Widget build(BuildContext context, WidgetRef ref) => TextFieldTapRegion(
    child: GlassContainer(
      quality: AppEffects.qualityOf(context, GlassQuality.standard),
      useOwnLayer: true,
      shape: const LiquidRoundedSuperellipse(borderRadius: AppRadius.pill),
      child: Pressable(
        key: const ValueKey('composer-quotes'),
        onTap: () => showQuoteEditor(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppIcon(
                AppIcons.quote,
                size: AppSizes.iconSm,
                color: context.glass.foregroundMuted,
              ),
              const Gap(AppSpacing.xs),
              Flexible(
                child: Text(
                  context.t.chat.quoteCount(count: count),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
