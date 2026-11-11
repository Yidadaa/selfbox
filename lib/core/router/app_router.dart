import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:talker_flutter/talker_flutter.dart';

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
    redirect: (context, state) =>
        state.uri.path == '/' ? const ChatRoute().location : null,
    observers: [TalkerRouteObserver(ref.watch(talkerProvider))],
    errorBuilder: (context, state) => const NotFoundPage(),
  );
  ref.onDispose(router.dispose);
  return router;
}
