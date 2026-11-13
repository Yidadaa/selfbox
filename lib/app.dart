import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_scroll_behavior.dart';
import 'core/theme/app_theme.dart';
import 'features/settings/domain/models/app_preferences.dart';
import 'features/settings/presentation/providers/app_preferences_controller.dart';
import 'gen/i18n/strings.g.dart';

class SelfboxApp extends ConsumerWidget {
  const SelfboxApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(
      appPreferencesControllerProvider.select(
        (preferences) => preferences.theme,
      ),
    );
    return MaterialApp.router(
      onGenerateTitle: (context) => context.t.app.name,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: switch (theme) {
        AppThemeChoice.system => ThemeMode.system,
        AppThemeChoice.light => ThemeMode.light,
        AppThemeChoice.dark => ThemeMode.dark,
      },
      locale: TranslationProvider.of(context).flutterLocale,
      supportedLocales: AppLocaleUtils.supportedLocales,
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      scrollBehavior: const AppScrollBehavior(),
      // Overlay entries sit outside page Materials and need their own baseline.
      builder: (context, child) => DefaultTextStyle(
        style: (Theme.of(context).textTheme.bodyMedium ?? const TextStyle())
            .copyWith(decoration: TextDecoration.none),
        child: child ?? const SizedBox.shrink(),
      ),
      routerConfig: ref.watch(appRouterProvider),
    );
  }
}
