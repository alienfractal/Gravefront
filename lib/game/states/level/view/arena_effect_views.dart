import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

import '../../../camera/pixel_viewport.dart';
import '../services/battle_logic_service.dart';
import '../services/level_cache_service.dart';

class ManaCrystalView extends PositionComponent {
  ManaCrystalView(this.powerUp, PixelViewport viewport, this._assets)
    : _viewport = viewport,
      super(
        position: Vector2(
          viewport.viewPoint(powerUp.position).dx - 5,
          viewport.viewPoint(powerUp.position).dy - 7,
        ),
        size: Vector2(10, 13),
        priority: 20,
      );

  final ManaPowerUp powerUp;
  final PixelViewport _viewport;
  final LevelCacheService _assets;
  late final SpriteAnimationComponent _sprite;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _sprite = _assets.manaCrystalComponent();
    await add(_sprite);
  }

  void sync(double elapsed) {
    final point = _viewport.viewPoint(powerUp.position);
    position = Vector2(point.dx - 5, point.dy - 7);
    if (_sprite.isLoaded) {
      _sprite.animationTicker!.currentIndex = (elapsed * 4).floor().isEven
          ? 0
          : 1;
    }
  }
}

class SelectionView extends PositionComponent {
  SelectionView() : super(size: Vector2.zero(), priority: 810);

  late final RectangleComponent _fill;
  late final RectangleComponent _outline;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _fill = RectangleComponent(
      size: Vector2.zero(),
      paint: Paint()..color = const Color(0x33F7D978),
    );
    _outline = RectangleComponent(
      size: Vector2.zero(),
      priority: 1,
      paint: Paint()
        ..color = const Color(0xFFEED17A)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..isAntiAlias = false,
    );
    await addAll([_fill, _outline]);
    scale = Vector2.zero();
  }

  void sync(Point<double>? a, Point<double>? b, PixelViewport viewport) {
    if (a == null || b == null || a.distanceTo(b) < 5) {
      scale = Vector2.zero();
      return;
    }
    final viewA = viewport.viewPoint(a);
    final viewB = viewport.viewPoint(b);
    position = Vector2(min(viewA.dx, viewB.dx), min(viewA.dy, viewB.dy));
    final boxSize = Vector2(
      (viewA.dx - viewB.dx).abs(),
      (viewA.dy - viewB.dy).abs(),
    );
    size = boxSize;
    _fill.size = boxSize.clone();
    _outline.size = boxSize.clone();
    scale = Vector2.all(1);
  }
}
