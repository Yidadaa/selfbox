import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../features/chat/presentation/pages/chat_page.dart';
import '../../features/chat/presentation/pages/image_viewer_page.dart';
import '../../features/chat/presentation/pages/message_search_page.dart';
import '../../features/memory/presentation/pages/memory_editor_page.dart';
import '../../features/memory/presentation/pages/memory_file_page.dart';
import '../../features/memory/presentation/pages/memory_page.dart';
import '../../features/settings/presentation/pages/about_page.dart';
import '../../features/settings/presentation/pages/ai_providers_page.dart';
import '../../features/settings/presentation/pages/me_page.dart';
import '../../features/settings/presentation/pages/model_page.dart';
import '../../features/settings/presentation/pages/profile_page.dart';
import '../../features/settings/presentation/pages/provider_page.dart';
import '../../features/settings/presentation/pages/storage_page.dart';
import '../../features/settings/presentation/pages/talker_page.dart';
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
          routes: [
            TypedGoRoute<MemoryFileRoute>(path: 'file'),
            TypedGoRoute<MemoryEditorRoute>(path: 'edit'),
          ],
        ),
      ],
    ),
    TypedStatefulShellBranch<MeBranch>(
      routes: [
        TypedGoRoute<MeRoute>(
          path: '/me',
          routes: [
            TypedGoRoute<ProfileRoute>(path: 'profile'),
            TypedGoRoute<StorageRoute>(path: 'storage'),
            TypedGoRoute<AiProvidersRoute>(path: 'providers'),
            TypedGoRoute<AboutRoute>(path: 'about'),
            TypedGoRoute<TalkerRoute>(path: 'logs'),
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

class ProfileRoute extends GoRouteData with $ProfileRoute {
  const ProfileRoute();
  static final GlobalKey<NavigatorState> $parentNavigatorKey = rootNavigatorKey;
  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const ProfilePage();
}

class StorageRoute extends GoRouteData with $StorageRoute {
  const StorageRoute();
  static final GlobalKey<NavigatorState> $parentNavigatorKey = rootNavigatorKey;
  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const StoragePage();
}

class AiProvidersRoute extends GoRouteData with $AiProvidersRoute {
  const AiProvidersRoute();
  static final GlobalKey<NavigatorState> $parentNavigatorKey = rootNavigatorKey;
  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const AiProvidersPage();
}

class AboutRoute extends GoRouteData with $AboutRoute {
  const AboutRoute();
  static final GlobalKey<NavigatorState> $parentNavigatorKey = rootNavigatorKey;
  @override
  Widget build(BuildContext context, GoRouterState state) => const AboutPage();
}

@TypedGoRoute<ImageViewerRoute>(path: '/image')
class ImageViewerRoute extends GoRouteData with $ImageViewerRoute {
  const ImageViewerRoute({required this.path, this.$extra});

  final List<String>? $extra;

  /// Media path relative to the app root, e.g. `media/<uuid>.jpg`.
  final String path;

  static final GlobalKey<NavigatorState> $parentNavigatorKey = rootNavigatorKey;

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      ImageViewerPage(path: path, paths: $extra);
}

@TypedGoRoute<MessageSearchRoute>(path: '/chat/search')
class MessageSearchRoute extends GoRouteData with $MessageSearchRoute {
  const MessageSearchRoute();
  static final GlobalKey<NavigatorState> $parentNavigatorKey = rootNavigatorKey;

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const MessageSearchPage();
}

/// Opens over the shell so the tab bar is hidden while reading a file.
class MemoryFileRoute extends GoRouteData with $MemoryFileRoute {
  const MemoryFileRoute({required this.path});
  static final GlobalKey<NavigatorState> $parentNavigatorKey = rootNavigatorKey;

  /// Memory path such as `user/profile.md`.
  final String path;

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      MemoryFilePage(path: path);
}

class MemoryEditorRoute extends GoRouteData with $MemoryEditorRoute {
  const MemoryEditorRoute({this.path});
  static final GlobalKey<NavigatorState> $parentNavigatorKey = rootNavigatorKey;

  final String? path;

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      MemoryEditorPage(path: path);
}

/// New provider when [id] is null.
class ProviderRoute extends GoRouteData with $ProviderRoute {
  const ProviderRoute({this.id});
  static final GlobalKey<NavigatorState> $parentNavigatorKey = rootNavigatorKey;

  final String? id;

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      ProviderPage(id: id);
}

class ModelRoute extends GoRouteData with $ModelRoute {
  const ModelRoute({required this.provider, required this.model});
  static final GlobalKey<NavigatorState> $parentNavigatorKey = rootNavigatorKey;

  final String provider;
  final String model;

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      ModelPage(providerId: provider, modelId: model);
}

class TalkerRoute extends GoRouteData with $TalkerRoute {
  const TalkerRoute();
  static final GlobalKey<NavigatorState> $parentNavigatorKey = rootNavigatorKey;

  @override
  Widget build(BuildContext context, GoRouterState state) => const TalkerPage();
}
