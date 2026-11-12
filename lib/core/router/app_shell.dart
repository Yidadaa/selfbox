import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../../features/chat/presentation/widgets/chat_composer.dart';
import '../theme/app_motion.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../widgets/app_canvas.dart';
import '../widgets/measure_size.dart';
import 'app_dock_tabs.dart';
import 'shell_scope.dart';

/// Root chrome shares the chat input and navigation in one floating dock.
class AppShell extends HookConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final chatDockHeight = useState(AppSizes.minTouchTarget);
    final tabDockHeight = useState(AppSizes.minTouchTarget);
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    final onChat = navigationShell.currentIndex == 0;
    final tabBottom = MediaQuery.paddingOf(context).bottom + AppSpacing.md;
    final chatBottom = onChat && keyboard > 0
        ? keyboard + AppSpacing.xs
        : tabBottom;
    final bottom = onChat ? chatBottom : tabBottom;
    final navigation = AppDockTabs(
      selectedIndex: navigationShell.currentIndex,
      onSelected: _onTabSelected,
    );

    return GlassScaffold(
      background: const AppCanvas(),
      // The dock owns the keyboard offset; the page keeps its full viewport.
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          IndexedStack(
            index: navigationShell.currentIndex,
            children: [
              for (final (index, child) in children.indexed)
                ShellScope(
                  bottomInset: index == 0
                      ? chatDockHeight.value + chatBottom
                      : tabDockHeight.value + tabBottom,
                  child: child,
                ),
            ],
          ),
          AnimatedPositioned(
            duration: AppMotion.fast,
            curve: AppMotion.emphasized,
            left: AppInsets.pageHorizontal,
            right: AppInsets.pageHorizontal,
            bottom: bottom,
            child: MeasureSize(
              onChange: (size) {
                if (onChat) {
                  chatDockHeight.value = size.height;
                } else {
                  tabDockHeight.value = size.height;
                }
              },
              child: onChat
                  ? ChatComposer(
                      keyboardOpen: keyboard > 0,
                      navigation: navigation,
                    )
                  : GlassContainer(
                      quality: GlassQuality.standard,
                      padding: const EdgeInsets.only(top: AppSpacing.xs),
                      shape: const LiquidRoundedSuperellipse(
                        borderRadius: AppRadius.xl,
                      ),
                      child: navigation,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
