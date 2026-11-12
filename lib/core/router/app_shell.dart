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
    final dockHeight = useState(AppSizes.minTouchTarget);
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    final onChat = navigationShell.currentIndex == 0;
    final bottom =
        (onChat && keyboard > 0
            ? keyboard
            : MediaQuery.paddingOf(context).bottom) +
        AppSpacing.xs;
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
          ShellScope(
            bottomInset: dockHeight.value + bottom,
            child: IndexedStack(
              index: navigationShell.currentIndex,
              children: children,
            ),
          ),
          AnimatedPositioned(
            duration: AppMotion.fast,
            curve: AppMotion.emphasized,
            left: AppSpacing.sm,
            right: AppSpacing.sm,
            bottom: bottom,
            child: MeasureSize(
              onChange: (size) => dockHeight.value = size.height,
              child: onChat
                  ? ChatComposer(
                      keyboardOpen: keyboard > 0,
                      navigation: navigation,
                    )
                  : GlassContainer(
                      quality: GlassQuality.premium,
                      useOwnLayer: true,
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
