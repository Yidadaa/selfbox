import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:talker_flutter/talker_flutter.dart';

import '../../features/settings/presentation/providers/app_preferences_controller.dart';
import '../logger/talker_provider.dart';
import 'app_routes.dart';
import 'not_found_page.dart';

part '../../gen/core/router/app_router.g.dart';

@Riverpod(keepAlive: true)
GoRouter appRouter(Ref ref) {
  final router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: const ChatRoute().location,
    routes: $appRoutes,
    redirect: (context, state) {
      final completed = ref
          .read(appPreferencesControllerProvider)
          .onboardingCompleted;
      final path = state.uri.path;
      final onboarding = path == const OnboardingRoute().location;
      final configuring =
          path == const OnboardingAiRoute().location ||
          path == const ProviderRoute().location ||
          path == const CustomPromptRoute().location ||
          path ==
              const ModelRoute(
                provider: '',
                model: '',
              ).location.split('?').first;
      if (!completed && !onboarding && !configuring) {
        return const OnboardingRoute().location;
      }
      if (completed &&
          (onboarding || path == const OnboardingAiRoute().location)) {
        return const ChatRoute().location;
      }
      return path == '/' ? const ChatRoute().location : null;
    },
    observers: [TalkerRouteObserver(ref.watch(talkerProvider))],
    errorBuilder: (context, state) => const NotFoundPage(),
  );
  ref.listen(
    appPreferencesControllerProvider.select(
      (value) => value.onboardingCompleted,
    ),
    (_, _) => router.refresh(),
  );
  ref.onDispose(router.dispose);
  return router;
}
