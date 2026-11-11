import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../features/chat/presentation/pages/chat_page.dart';
import '../../features/memory/presentation/pages/memory_page.dart';
import '../../features/settings/presentation/pages/me_page.dart';
import 'app_shell.dart';

part '../../gen/core/router/app_routes.g.dart';

/// Pushed full-screen routes (viewers, editors) cover the tab bar.
final rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

@TypedStatefulShellRoute<AppShellRoute>(
  branches: [
    TypedStatefulShellBranch<ChatBranch>(
      routes: [TypedGoRoute<ChatRoute>(path: '/chat')],
    ),
    TypedStatefulShellBranch<MemoryBranch>(
      routes: [TypedGoRoute<MemoryRoute>(path: '/memory')],
    ),
    TypedStatefulShellBranch<MeBranch>(
      routes: [TypedGoRoute<MeRoute>(path: '/me')],
    ),
  ],
)
class AppShellRoute extends StatefulShellRouteData {
  const AppShellRoute();

  @override
  Widget builder(
    BuildContext context,
    GoRouterState state,
    StatefulNavigationShell navigationShell,
  ) => navigationShell;

  static Widget $navigatorContainerBuilder(
    BuildContext context,
    StatefulNavigationShell navigationShell,
    List<Widget> children,
  ) => AppShell(navigationShell: navigationShell, children: children);
}

class ChatBranch extends StatefulShellBranchData {
  const ChatBranch();
}

class MemoryBranch extends StatefulShellBranchData {
  const MemoryBranch();
}

class MeBranch extends StatefulShellBranchData {
  const MeBranch();
}

class ChatRoute extends GoRouteData with $ChatRoute {
  const ChatRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => const ChatPage();
}

class MemoryRoute extends GoRouteData with $MemoryRoute {
  const MemoryRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => const MemoryPage();
}

class MeRoute extends GoRouteData with $MeRoute {
  const MeRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => const MePage();
}
