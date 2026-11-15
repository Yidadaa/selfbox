part of 'app_routes.dart';

@TypedGoRoute<MessageExpandedRoute>(path: '/chat/message/:id')
class MessageExpandedRoute extends GoRouteData with $MessageExpandedRoute {
  const MessageExpandedRoute({required this.id, this.$extra});
  final int id;
  final Message? $extra;

  static final GlobalKey<NavigatorState> $parentNavigatorKey = rootNavigatorKey;

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) =>
      NoTransitionPage<void>(
        key: state.pageKey,
        child: MessageExpandedPage(id: id, initial: $extra),
      );
}

@TypedGoRoute<MessageLocationRoute>(path: '/chat/at/:id')
class MessageLocationRoute extends GoRouteData with $MessageLocationRoute {
  const MessageLocationRoute({required this.id});
  final int id;
  static final GlobalKey<NavigatorState> $parentNavigatorKey = rootNavigatorKey;

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      MessageLocationPage(id: id);
}
