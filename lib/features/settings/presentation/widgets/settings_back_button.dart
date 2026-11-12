import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../../../../gen/i18n/strings.g.dart';

class SettingsBackButton extends StatelessWidget {
  const SettingsBackButton({super.key});
  @override
  Widget build(BuildContext context) => GlassIconButton(
    size: 40,
    quality: GlassQuality.premium,
    icon: const Icon(Icons.arrow_back_ios_new_rounded),
    semanticLabel: context.t.common.close,
    onPressed: () => context.pop(),
  );
}
