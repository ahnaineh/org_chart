import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

typedef OnWidgetSizeChange = void Function(Size size);

class MeasureSize extends SingleChildRenderObjectWidget {
  final OnWidgetSizeChange onChange;

  const MeasureSize({
    super.key,
    required this.onChange,
    required super.child,
  });

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderMeasureSize(onChange);
  }

  @override
  void updateRenderObject(
      BuildContext context, covariant _RenderMeasureSize renderObject) {
    renderObject.onChange = onChange;
  }
}

class _RenderMeasureSize extends RenderProxyBox {
  _RenderMeasureSize(this.onChange);

  OnWidgetSizeChange onChange;
  Size? _oldSize;

  @override
  void performLayout() {
    super.performLayout();
    final Size newSize = child?.size ?? Size.zero;
    if (_oldSize == newSize) return;
    _oldSize = newSize;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      onChange(newSize);
    });
  }
}
