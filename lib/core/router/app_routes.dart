import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../features/chat/presentation/pages/chat_page.dart';
import '../../features/chat/presentation/pages/image_viewer_page.dart';
import '../../features/memory/presentation/pages/memory_file_page.dart';
import '../../features/memory/presentation/pages/memory_page.dart';
import '../../features/settings/presentation/pages/me_page.dart';
import '../../features/settings/presentation/pages/model_page.dart';
import '../../features/settings/presentation/pages/provider_page.dart';
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
      routes: [
        TypedGoRoute<MemoryRoute>(
          path: '/memory',
          routes: [TypedGoRoute<MemoryFileRoute>(path: 'file')],
        ),
      ],
    ),
    TypedStatefulShellBranch<MeBranch>(
      routes: [
        TypedGoRoute<MeRoute>(
          path: '/me',
          routes: [
            TypedGoRoute<ProviderRoute>(path: 'provider'),
            TypedGoRoute<ModelRoute>(path: 'model'),
          ],
        ),
      ],
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

@TypedGoRoute<ImageViewerRoute>(path: '/image')
class ImageViewerRoute extends GoRouteData with $ImageViewerRoute {
  const ImageViewerRoute({required this.path});

  /// Media path relative to the app root, e.g. `media/<uuid>.jpg`.
  final String path;

  static final GlobalKey<NavigatorState> $parentNavigatorKey = rootNavigatorKey;

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      ImageViewerPage(path: path);
}

/// Stays inside the memory branch so the tab bar remains visible.
class MemoryFileRoute extends GoRouteData with $MemoryFileRoute {
  const MemoryFileRoute({required this.path});

  /// Memory path such as `user/profile.md`.
  final String path;

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      MemoryFilePage(path: path);
}

/// New provider when [id] is null.
class ProviderRoute extends GoRouteData with $ProviderRoute {
  const ProviderRoute({this.id});

  final String? id;

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      ProviderPage(id: id);
}

class ModelRoute extends GoRouteData with $ModelRoute {
  const ModelRoute({required this.provider, required this.model});

  final String provider;
  final String model;

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      ModelPage(providerId: provider, modelId: model);
}
