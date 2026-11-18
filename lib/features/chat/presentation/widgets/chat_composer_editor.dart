import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:selfbox/core/theme/sdk_cupertino.dart';
import 'package:selfbox/core/theme/sdk_material.dart';

import '../../../../core/theme/app_glass_theme.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../gen/i18n/strings.g.dart';
import '../../../settings/presentation/providers/account_providers.dart';
import '../providers/composer_controller.dart';

/// Only line-count transitions rebuild the field's vertical padding.
class ChatComposerEditor extends ConsumerWidget {
  const ChatComposerEditor({
    required this.controller,
    required this.focusNode,
    required this.maxHeight,
    super.key,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final double maxHeight;

  @override
  Widget build(BuildContext context, WidgetRef ref) => LayoutBuilder(
    builder: (context, constraints) => _Editor(
      controller: controller,
      focusNode: focusNode,
      maxHeight: maxHeight,
      width: constraints.maxWidth,
    ),
  );
}

class _Editor extends HookConsumerWidget {
  const _Editor({
    required this.controller,
    required this.focusNode,
    required this.maxHeight,
    required this.width,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final double maxHeight;
  final double width;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final aiMode = ref.watch(
      composerControllerProvider.select((state) => state.aiMode),
    );
    final glass = context.glass;
    final agentName = ref.watch(
      userProfileProvider.select(
        (value) => value.value?.agentName.trim() ?? '',
      ),
    );
    // Cupertino overlays use the alphabetic baseline reported by Text.
    final style = Theme.of(context).textTheme.bodyLarge?.copyWith(
      textBaseline: TextBaseline.alphabetic,
      color: glass.foreground,
    );
    final direction = Directionality.of(context);
    final scaler = MediaQuery.textScalerOf(context);
    final lines = useMemoized(
      () => _LineMeasure(style, direction, scaler, width),
      [style, direction, scaler, width],
    );
    useEffect(() => lines.dispose, [lines]);
    final multiline = useListenableSelector(
      controller,
      () => lines.isMultiline(controller.text),
    );
    return ConstrainedBox(
      constraints: BoxConstraints(
        minHeight: AppSizes.minTouchTarget,
        maxHeight: maxHeight,
      ),
      child: CupertinoTextField(
        controller: controller,
        focusNode: focusNode,
        onChanged: ref.read(composerControllerProvider.notifier).setText,
        onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
        minLines: 1,
        maxLines: 6,
        keyboardType: TextInputType.multiline,
        textAlignVertical: TextAlignVertical.center,
        placeholder: aiMode
            ? context.t.chat.aiInputHint(
                agentName: agentName.isEmpty
                    ? context.t.me.agentDefaultName
                    : agentName,
              )
            : context.t.chat.inputHint,
        style: style,
        placeholderStyle: style?.copyWith(color: glass.foregroundMuted),
        padding: EdgeInsets.symmetric(
          vertical: multiline ? AppSpacing.composerVertical : 0,
        ),
        decoration: null,
      ),
    );
  }
}

/// Cache selection/composition-only updates and measure one-line overflow.
class _LineMeasure {
  _LineMeasure(
    this.style,
    TextDirection direction,
    TextScaler scaler,
    this.width,
  ) : painter = TextPainter(
        textDirection: direction,
        textScaler: scaler,
        maxLines: 1,
      );

  final TextStyle? style;
  final double width;
  final TextPainter painter;
  String? _text;
  bool _multiline = false;

  bool isMultiline(String text) {
    if (text == _text) return _multiline;
    _text = text;
    if (text.isEmpty || text.contains('\n')) {
      return _multiline = text.isNotEmpty;
    }
    // Character counts cannot safely predict CJK, emoji or scaled glyph widths.
    painter.text = TextSpan(text: text, style: style);
    painter.layout(maxWidth: width);
    return _multiline = painter.didExceedMaxLines;
  }

  void dispose() => painter.dispose();
}
