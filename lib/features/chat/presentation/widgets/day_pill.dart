import 'package:flutter/material.dart';

import '../../../../core/theme/app_glass_theme.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../gen/i18n/strings.g.dart';
import 'date_labels.dart';

/// Centered "今天" / "8月7日" separator between days.
///
/// A flat tinted pill rather than refractive glass: it repeats down a long
/// scrolling list, where real-time blur would blow the GPU budget.
class DayPill extends StatelessWidget {
  const DayPill({required this.day, required this.now, super.key});

  final DateTime day;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final glass = context.glass;
    final label = formatDayLabel(
      day,
      now,
      locale: LocaleSettings.currentLocale.languageTag,
      today: t.chat.today,
      yesterday: t.chat.yesterday,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Center(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: glass.surfaceTint,
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xxs,
            ),
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelMedium
                  ?.copyWith(color: glass.foregroundMuted),
            ),
          ),
        ),
      ),
    );
  }
}
