import 'package:flutter/material.dart';

import '../../../../core/widgets/app_action_button.dart';

/// Full-width glass action button; ignores taps while [busy].
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    required this.label,
    required this.onTap,
    this.icon,
    this.busy = false,
    super.key,
  });

  final String label;
  final VoidCallback onTap;
  final IconData? icon;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return AppActionButton(
      label: label,
      onPressed: onTap,
      icon: icon,
      busy: busy,
      variant: AppActionButtonVariant.primary,
    );
  }
}
