import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../../camera/pixel_viewport.dart';
import '../handlers/unit_animation_handler.dart';
import '../services/battle_logic_service.dart';
import '../services/level_cache_service.dart';
import 'health_bar_view.dart';

/// A Flame component for one simulation unit. The animation clock belongs to
/// BattleUnit, so a render frame cannot advance combat or death timing.
class UnitView extends PositionComponent {
  UnitView(this.unit, this._assets, this._viewport, this._battle)
    : super(size: Vector2.zero());

  final BattleUnit unit;
  final LevelCacheService _assets;
  final PixelViewport _viewport;
  final BattleState _battle;
  final UnitAnimationHandler _animation = const UnitAnimationHandler();
  late final SpriteAnimationComponent _sprite;
  late final CircleComponent _selectionRing;
  late final RectangleComponent _hitFlash;
  late final HealthBarView _healthBar;

  /// Current sprite extent in arena coordinates, including its animation pose.
  Rect get spriteBounds {
    final depthScale = scale.x;
    return Rect.fromLTWH(
      position.x + _sprite.position.x * depthScale,
      position.y + _sprite.position.y * depthScale,
      _sprite.size.x * depthScale,
      _sprite.size.y * depthScale,
    );
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _sprite = _assets.unitComponent(
      unit.faction,
      unit.role,
      facing: unit.facing,
    );
    final isPlayer = unit.faction == _battle.playerFaction;
    final accent = isPlayer ? const Color(0xFFE7C76D) : const Color(0xFFE47A69);
    _selectionRing = CircleComponent(
      radius: 15,
      position: Vector2(0, 3),
      anchor: Anchor.center,
      scale: Vector2.zero(),
      paint: Paint()
        ..color = accent.withValues(alpha: 0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..isAntiAlias = false,
    );
    _hitFlash = RectangleComponent(
      size: Vector2.zero(),
      priority: 1,
      paint: Paint()..color = const Color(0x00000000),
    );
    _healthBar = HealthBarView(width: 24, color: accent, priority: 2);
    await addAll([
      CircleComponent(
        radius: 12,
        position: Vector2(0, 3),
        anchor: Anchor.center,
        scale: Vector2(1, 0.25),
        paint: Paint()
          ..color = const Color(0x990D1D15)
          ..isAntiAlias = false,
      ),
      _selectionRing,
      _sprite,
      _hitFlash,
      _healthBar,
    ]);
    sync();
  }

  void sync() {
    final name = assetNameFor(unit.faction, unit.role);
    final state = _animation.stateFor(unit);
    final atlas = _assets.unitAtlas(unit.faction, unit.role, state);
    final walkAtlas = _assets.unitAtlas(unit.faction, unit.role, 'walk');

    final point = _viewport.viewPoint(unit.position);
    position = Vector2(point.dx, point.dy);
    scale = Vector2.all(_animation.scaleFor(unit));
    priority = 100 + point.dy.round();
    _selectionRing.scale = unit.isAlive && _battle.selectedIds.contains(unit.id)
        ? Vector2(1, 8 / 30)
        : Vector2.zero();

    final animation = atlas.animationFor(unit.facing);
    if (_sprite.animation != animation) _sprite.animation = animation;
    _sprite.animationTicker!.currentIndex = _animation.frameFor(
      unit,
      name,
      state,
      atlas,
    );
    final baseHeight = _animation.heightFor(unit.role, name);
    final rect = _animation.destinationRect(
      Offset.zero,
      walkAtlas,
      atlas,
      baseHeight,
    );
    _sprite.position = Vector2(rect.left, rect.top);
    _sprite.size = Vector2(rect.width, rect.height);
    _hitFlash.position = Vector2(rect.left, rect.top);
    _hitFlash.size = Vector2(rect.width, rect.height);
    _hitFlash.paint.color = unit.isAlive && unit.hitFlash > 0
        ? const Color(0x66FFFFFF)
        : const Color(0x00000000);
    _healthBar.scale = unit.isAlive ? Vector2.all(1) : Vector2.zero();
    _healthBar.position = Vector2(-12, -baseHeight - 4);
    _healthBar.setRatio(unit.health / unit.stats.maxHealth);
  }
}
