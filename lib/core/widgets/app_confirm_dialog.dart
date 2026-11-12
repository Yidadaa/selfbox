import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../theme/app_dialog_tokens.dart';
import '../theme/app_glass_theme.dart';
import '../theme/app_spacing.dart';

/// An opaque confirmation dialog with the Liquid alert's proportions.
class AppConfirmDialog extends StatelessWidget {
  const AppConfirmDialog({
    required this.title,
    required this.secondaryLabel,
    required this.primaryLabel,
    required this.onPrimary,
    this.destructive = false,
    super.key,
  });

  final String title;
  final String secondaryLabel;
  final String primaryLabel;
  final VoidCallback onPrimary;
  final bool destructive;

  @override
  Widget build(BuildContext context) => Dialog(
    backgroundColor: context.glass.bubbleOther,
    surfaceTintColor: context.glass.bubbleOther,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(AppDialogTokens.radius)),
    ),
    insetPadding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.md,
      vertical: AppSpacing.xl,
    ),
    clipBehavior: Clip.antiAlias,
    child: SizedBox(
      width: AppDialogTokens.width,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: AppDialogTokens.headerInsets,
              child: Text(
                title,
                style: TextStyle(
                  color: context.glass.onBubbleOther,
                  fontSize: AppDialogTokens.labelSize,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.none,
                ),
              ),
            ),
            Padding(
              padding: AppDialogTokens.actionInsets,
              child: _DialogActions(
                secondaryLabel: secondaryLabel,
                primaryLabel: primaryLabel,
                destructive: destructive,
                onSecondary: () => Navigator.of(context).pop(),
                onPrimary: () {
                  Navigator.of(context).pop();
                  onPrimary();
                },
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _DialogActions extends StatelessWidget {
  const _DialogActions({
    required this.secondaryLabel,
    required this.primaryLabel,
    required this.onSecondary,
    required this.onPrimary,
    required this.destructive,
  });

  final String secondaryLabel;
  final String primaryLabel;
  final VoidCallback onSecondary;
  final VoidCallback onPrimary;
  final bool destructive;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final labelWidth =
          (constraints.maxWidth - AppSpacing.xs) / 2 - 2 * AppSpacing.md;
      final baseStyle = DefaultTextStyle.of(context).style;
      final textScaler = MediaQuery.textScalerOf(context);
      final labelsFit =
          [
            (secondaryLabel, FontWeight.w500),
            (primaryLabel, FontWeight.w600),
          ].every((entry) {
            final painter = TextPainter(
              text: TextSpan(
                text: entry.$1,
                style: baseStyle.merge(
                  TextStyle(
                    fontSize: AppDialogTokens.labelSize,
                    fontWeight: entry.$2,
                  ),
                ),
              ),
              maxLines: 1,
              textDirection: Directionality.of(context),
              textScaler: textScaler,
            )..layout();
            final fits = painter.width <= labelWidth;
            painter.dispose();
            return fits;
          });
      final secondary = _DialogActionButton(
        label: secondaryLabel,
        onTap: onSecondary,
      );
      final primary = _DialogActionButton(
        label: primaryLabel,
        onTap: onPrimary,
        isPrimary: true,
        destructive: destructive,
      );
      return labelsFit
          ? Row(
              children: [
                Expanded(child: secondary),
                const Gap(AppSpacing.xs),
                Expanded(child: primary),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [secondary, const Gap(AppSpacing.xs), primary],
            );
    },
  );
}

class _DialogActionButton extends StatelessWidget {
  const _DialogActionButton({
    required this.label,
    required this.onTap,
    this.isPrimary = false,
    this.destructive = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool isPrimary;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final color = destructive
        ? context.glass.dialogDestructive
        : context.glass.onBubbleOther;
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        backgroundColor: context.glass.dialogActionFill,
        foregroundColor: color,
        minimumSize: const Size(0, AppSizes.minTouchTarget),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        shape: const StadiumBorder(),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: color,
          fontSize: AppDialogTokens.labelSize,
          fontWeight: isPrimary ? FontWeight.w600 : FontWeight.w500,
          decoration: TextDecoration.none,
        ),
      ),
    );
  }
}
