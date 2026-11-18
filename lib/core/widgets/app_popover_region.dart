import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:selfbox/core/theme/sdk_material.dart';

import '../theme/app_popover_tokens.dart';
import 'app_action_popover.dart' show AppActionPopover;
import 'app_popover_surface.dart';

class AppPopoverRegion extends HookWidget {
  const AppPopoverRegion({
    required this.actions,
    required this.builder,
    this.radius = AppPopoverTokens.radius,
    super.key,
  });
  final List<AppPopoverAction> actions;
  final Widget Function(BuildContext, ValueChanged<Offset>) builder;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final anchor = useState<Offset?>(null);
    final hovered = useState<int?>(null);
    final isOpen = anchor.value != null;
    final itemKeys = useMemoized(
      () => isOpen
          ? List<GlobalKey>.generate(actions.length, (_) => GlobalKey())
          : const <GlobalKey>[],
      [actions.length, isOpen],
    );
    void close() {
      hovered.value = null;
      anchor.value = null;
    }

    void activate(int index) {
      close();
      actions[index].onPressed();
    }

    return Stack(
      fit: StackFit.passthrough,
      children: [
        Listener(
          onPointerMove: (event) {
            if (anchor.value == null) return;
            hovered.value = popoverActionAt(itemKeys, event.position);
          },
          onPointerUp: (event) {
            if (anchor.value == null) return;
            final index = popoverActionAt(itemKeys, event.position);
            if (index == null) {
              hovered.value = null;
            } else {
              activate(index);
            }
          },
          onPointerCancel: (_) => hovered.value = null,
          child: builder(context, (point) {
            hovered.value = null;
            anchor.value = point;
          }),
        ),
        if (anchor.value case final point?)
          _PopoverOverlay(
            anchor: point,
            radius: radius,
            itemKeys: itemKeys,
            highlightedIndex: hovered.value,
            onClose: close,
            actions: [
              for (final (index, action) in actions.indexed)
                AppPopoverAction(
                  label: action.label,
                  icon: action.icon,
                  destructive: action.destructive,
                  onPressed: () => activate(index),
                ),
            ],
          ),
      ],
    );
  }
}

class _PopoverOverlay extends HookWidget {
  const _PopoverOverlay({
    required this.anchor,
    required this.radius,
    required this.itemKeys,
    required this.highlightedIndex,
    required this.onClose,
    required this.actions,
  });
  final Offset anchor;
  final double radius;
  final List<GlobalKey> itemKeys;
  final int? highlightedIndex;
  final VoidCallback onClose;
  final List<AppPopoverAction> actions;

  @override
  Widget build(BuildContext context) {
    final portal = useMemoized(OverlayPortalController.new);
    useEffect(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) portal.show();
      });
      return null;
    }, [portal]);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) onClose();
      },
      child: OverlayPortal(
        overlayLocation: OverlayChildLocation.rootOverlay,
        controller: portal,
        overlayChildBuilder: (_) => Stack(
          children: [
            ModalBarrier(
              onDismiss: onClose,
              semanticsLabel: MaterialLocalizations.of(context)
                  .modalBarrierDismissLabel,
            ),
            AppActionPopover(
              anchor: anchor,
              radius: radius,
              itemKeys: itemKeys,
              highlightedIndex: highlightedIndex,
              actions: actions,
            ),
          ],
        ),
        child: const SizedBox.shrink(),
      ),
    );
  }
}
