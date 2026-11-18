import 'package:selfbox/core/theme/sdk_material.dart';

import '../../../../core/widgets/app_artwork.dart';
import '../../../../core/widgets/app_page_button.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../gen/i18n/strings.g.dart';

class SettingsLoadFailure extends StatelessWidget {
  const SettingsLoadFailure({required this.onRetry, super.key});
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => EmptyState(
    illustration: BrandArt.error,
    label: context.t.settings.errors.generic,
    action: AppPageButton(label: context.t.common.retry, onPressed: onRetry),
  );
}
