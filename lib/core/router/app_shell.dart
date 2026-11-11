import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../../gen/i18n/strings.g.dart';
import '../theme/app_glass_theme.dart';
import '../widgets/app_canvas.dart';
import 'shell_scope.dart';

/// Root chrome: one floating glass tab bar over three independent branches.
class AppShell extends StatelessWidget {
  const AppShell({
    required this.navigationShell,
    required this.children,
    super.key,
  });

  final StatefulNavigationShell navigationShell;
  final List<Widget> children;

  void _onTabSelected(int index) {
    HapticFeedback.selectionClick();
    // Re-tapping the active tab pops that branch back to its root.
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final glass = context.glass;
    final label = Theme.of(context).textTheme.labelSmall;
    final tabBar = GlassTabBar.bottom(
      selectedIndex: navigationShell.currentIndex,
      onTabSelected: _onTabSelected,
      selectedIconColor: glass.foreground,
      unselectedIconColor: glass.foregroundMuted,
      selectedLabelColor: glass.foreground,
      unselectedLabelColor: glass.foregroundMuted,
      selectedLabelStyle: label?.copyWith(fontWeight: FontWeight.w600),
      unselectedLabelStyle: label?.copyWith(fontWeight: FontWeight.w500),
      tabs: [
        GlassTab(
          icon: const Icon(Icons.chat_bubble_outline_rounded),
          activeIcon: const Icon(Icons.chat_bubble_rounded),
          label: t.tabs.chat,
        ),
        GlassTab(
          icon: const Icon(Icons.auto_awesome_outlined),
          activeIcon: const Icon(Icons.auto_awesome),
          label: t.tabs.memory,
        ),
        GlassTab(
          icon: const Icon(Icons.person_outline_rounded),
          activeIcon: const Icon(Icons.person_rounded),
          label: t.tabs.me,
        ),
      ],
    );

    return GlassScaffold(
      background: const AppCanvas(),
      // The keyboard covers the tab bar; pages with inputs lift themselves.
      resizeToAvoidBottomInset: false,
      bottomBar: tabBar,
      body: ShellScope(
        bottomInset:
            tabBar.preferredSize.height + MediaQuery.paddingOf(context).bottom,
        child: IndexedStack(
          index: navigationShell.currentIndex,
          children: children,
        ),
      ),
    );
  }
}
