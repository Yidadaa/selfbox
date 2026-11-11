import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Reports its child's laid-out size whenever it changes, e.g. so a list can
/// pad itself for a floating composer that grows with multi-line input.
class MeasureSize extends SingleChildRenderObjectWidget {
  const MeasureSize({required this.onChange, required super.child, super.key});

  final ValueChanged<Size> onChange;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      RenderMeasureSize(onChange);

  @override
  void updateRenderObject(
    BuildContext context,
    covariant RenderMeasureSize renderObject,
  ) => renderObject.onChange = onChange;
}

class RenderMeasureSize extends RenderProxyBox {
  RenderMeasureSize(this.onChange);

  ValueChanged<Size> onChange;
  Size? _last;

  @override
  void performLayout() {
    super.performLayout();
    final current = size;
    if (current == _last) return;
    _last = current;
    // Reporting during layout would mark ancestors dirty mid-frame.
    WidgetsBinding.instance.addPostFrameCallback((_) => onChange(current));
  }
}
