import 'package:flutter/material.dart';

import '../../../../core/widgets/empty_state.dart';
import '../../../../gen/i18n/strings.g.dart';
import 'primary_button.dart';

class SettingsLoadFailure extends StatelessWidget {
  const SettingsLoadFailure({required this.onRetry, super.key});
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => EmptyState(
    label: context.t.settings.errors.generic,
    action: PrimaryButton(label: context.t.common.retry, onTap: onRetry),
  );
}
