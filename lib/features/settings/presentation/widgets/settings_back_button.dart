import 'package:go_router/go_router.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:selfbox/core/theme/sdk_material.dart';

import '../../../../core/theme/app_effects.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_icon.dart';
import '../../../../gen/i18n/strings.g.dart';

class SettingsBackButton extends StatelessWidget {
  const SettingsBackButton({super.key});
  @override
  Widget build(BuildContext context) => GlassIconButton(
    size: AppSizes.minTouchTarget,
    quality: AppEffects.qualityOf(context, GlassQuality.premium),
    icon: const AppIcon(AppIcons.back),
    semanticLabel: context.t.common.close,
    onPressed: () => context.pop(),
  );
}
