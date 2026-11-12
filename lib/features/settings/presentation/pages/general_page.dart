import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../../../../core/error/failure_message.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_list_tile.dart';
import '../../../../core/widgets/app_page_scaffold.dart';
import '../../../../gen/i18n/strings.g.dart';
import '../../domain/models/app_preferences.dart';
import '../providers/app_preferences_controller.dart';
import '../widgets/settings_back_button.dart';
import '../widgets/settings_picker_sheet.dart';

class GeneralPage extends ConsumerWidget {
  const GeneralPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preferences = ref.watch(appPreferencesControllerProvider);
    final labels = context.t.general;
    final language =
        preferences.language ??
        switch (LocaleSettings.currentLocale) {
          AppLocale.zhCn => AppLanguageChoice.zhCn,
          AppLocale.en => AppLanguageChoice.en,
        };

    return AppPageScaffold(
      title: context.t.me.general,
      leading: const SettingsBackButton(),
      body: ListView(
        padding: AppPageInsets.of(context),
        children: [
          GlassGroupedSection(
            margin: AppInsets.section,
            quality: GlassQuality.standard,
            shape: const LiquidRoundedSuperellipse(borderRadius: AppRadius.lg),
            children: [
              AppListTile(
                icon: Icons.brightness_6_outlined,
                title: labels.theme,
                value: switch (preferences.theme) {
                  AppThemeChoice.system => labels.system,
                  AppThemeChoice.light => labels.light,
                  AppThemeChoice.dark => labels.dark,
                },
                onTap: () => _pickTheme(context, ref, preferences.theme),
              ),
              AppListTile(
                icon: Icons.language_rounded,
                title: labels.language,
                value: switch (language) {
                  AppLanguageChoice.zhCn => labels.chinese,
                  AppLanguageChoice.en => labels.english,
                },
                onTap: () => _pickLanguage(context, ref, language),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _pickTheme(
    BuildContext context,
    WidgetRef ref,
    AppThemeChoice current,
  ) => showSettingsPicker(
    context: context,
    title: context.t.general.theme,
    pickerKey: const ValueKey('theme-picker'),
    labels: [
      context.t.general.system,
      context.t.general.light,
      context.t.general.dark,
    ],
    initialIndex: AppThemeChoice.values.indexOf(current),
    onSave: (index) async {
      final result = await ref
          .read(appPreferencesControllerProvider.notifier)
          .setTheme(AppThemeChoice.values[index]);
      if (context.mounted) {
        showOutcome(context, failure: result.getLeft().toNullable());
      }
      return result.isRight();
    },
  );

  Future<void> _pickLanguage(
    BuildContext context,
    WidgetRef ref,
    AppLanguageChoice current,
  ) => showSettingsPicker(
    context: context,
    title: context.t.general.language,
    pickerKey: const ValueKey('language-picker'),
    labels: [context.t.general.chinese, context.t.general.english],
    initialIndex: AppLanguageChoice.values.indexOf(current),
    onSave: (index) async {
      final result = await ref
          .read(appPreferencesControllerProvider.notifier)
          .setLanguage(AppLanguageChoice.values[index]);
      if (context.mounted) {
        showOutcome(context, failure: result.getLeft().toNullable());
      }
      return result.isRight();
    },
  );
}
