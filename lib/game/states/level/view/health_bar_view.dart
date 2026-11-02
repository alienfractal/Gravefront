import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

/// Three rectangle components that follow a health value without painting on
/// the canvas directly from a view.
class HealthBarView extends PositionComponent {
  HealthBarView({required double width, required Color color, super.priority})
    : _width = width,
      _color = color,
      super(size: Vector2(width, 3));

  final double _width;
  final Color _color;
  late final RectangleComponent _fill;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _fill = RectangleComponent(
      size: Vector2(_width, 3),
      paint: Paint()..color = _color,
      priority: 2,
    );
    await addAll([
      RectangleComponent(
        position: Vector2(-1, -1),
        size: Vector2(_width + 2, 5),
        paint: Paint()..color = const Color(0xDD000000),
      ),
      RectangleComponent(
        size: Vector2(_width, 3),
        paint: Paint()..color = const Color(0xFF5B261F),
        priority: 1,
      ),
      _fill,
    ]);
  }

  void setRatio(double ratio) {
    _fill.size = Vector2((_width * ratio.clamp(0.0, 1.0)).roundToDouble(), 3);
  }
}
