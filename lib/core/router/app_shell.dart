import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../../features/chat/presentation/widgets/chat_composer.dart';
import '../theme/app_effects.dart';
import '../theme/app_glass_theme.dart';
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
    // Size reports update branch insets without rebuilding the measured dock.
    final dock = useMemoized(
      () => _Dock(
        onChat: onChat,
        keyboardOpen: keyboard > 0,
        navigation: AppDockTabs(
          selectedIndex: navigationShell.currentIndex,
          onSelected: _onTabSelected,
        ),
      ),
      [navigationShell, navigationShell.currentIndex, keyboard > 0],
    );

    return Stack(
      fit: StackFit.expand,
      children: [
        const AppCanvas(),
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
          duration: AppMotion.duration(context, AppMotion.fast),
          curve: AppMotion.emphasized,
          left: AppInsets.pageHorizontal,
          right: AppInsets.pageHorizontal,
          bottom: bottom,
          child: RepaintBoundary(
            key: const ValueKey('app-dock-repaint-boundary'),
            child: MeasureSize(
              onChange: (size) {
                if (onChat) {
                  chatDockHeight.value = size.height;
                } else {
                  tabDockHeight.value = size.height;
                }
              },
              child: dock,
            ),
          ),
        ),
      ],
    );
  }
}

class _Dock extends ConsumerWidget {
  const _Dock({
    required this.onChat,
    required this.keyboardOpen,
    required this.navigation,
  });

  final bool onChat;
  final bool keyboardOpen;
  final Widget navigation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (onChat) {
      return ChatComposer(keyboardOpen: keyboardOpen, navigation: navigation);
    }
    final glass = context.glass;
    return GlassContainer(
      quality: AppEffects.qualityOf(context, GlassQuality.standard),
      useOwnLayer: true,
      settings: LiquidGlassSettings(
        blur: glass.chromeBlur,
        glassColor: glass.chromeTint,
      ),
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      shape: const LiquidRoundedSuperellipse(borderRadius: AppRadius.xl),
      child: navigation,
    );
  }
}
