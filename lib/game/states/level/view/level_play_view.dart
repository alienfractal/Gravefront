import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

import '../../../camera/pixel_viewport.dart';
import '../services/battle_logic_service.dart';
import '../services/level_cache_service.dart';
import 'arena_effect_views.dart';
import 'health_bar_view.dart';
import 'hitbox_view.dart';
import 'keep_collision_view.dart';
import 'unit_view.dart';

/// The arena owns every visible battlefield component.
class LevelPlayView extends PositionComponent {
  LevelPlayView(
    this.battle,
    this._assets,
    this._viewport, {
    required this.showHitboxes,
  }) : super(
         position: Vector2(0, PixelViewport.headerHeight),
         size: Vector2(PixelViewport.width, PixelViewport.height),
       );

  final BattleState battle;
  final LevelCacheService _assets;
  final PixelViewport _viewport;
  final bool Function() showHitboxes;
  final Map<int, UnitView> _units = {};
  late final SpriteComponent _hereticKeep;
  late final SpriteComponent _hexenKeep;
  final Map<AttackEffect, SpriteAnimationComponent> _effects = {};
  final Map<Faction, HealthBarView> _keepBars = {};
  late final SelectionView _selection;
  ManaCrystalView? _mana;
  Point<double>? selectionStart;
  Point<double>? selectionEnd;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    final children = <Component>[
      _assets.terrainComponent(battle.campaignLevel.map)
        ..position = Vector2.zero(),
    ];
    for (final faction in Faction.values) {
      final point = _viewport.viewPoint(battle.basePosition(faction));
      final keepSpec = switch (faction) {
        Faction.heretic => _assets.hereticKeep,
        Faction.hexen => _assets.hexenKeep,
      };
      final keep = keepSpec.getSpriteComponent(priority: 10)
        ..size = Vector2(83, 102)
        ..anchor = Anchor.center
        ..position = Vector2(point.dx, point.dy - 28);
      keep.size = Vector2(83, 102);
      switch (faction) {
        case Faction.heretic:
          _hereticKeep = keep;
          break;
        case Faction.hexen:
          _hexenKeep = keep;
          break;
      }

      children.add(keep);
      final bar = HealthBarView(
        width: 40,
        color: faction == Faction.heretic
            ? const Color(0xFFD08A53)
            : const Color(0xFF80A6D4),
        priority: 800,
      )..position = Vector2(point.dx - 20, point.dy - 77);
      _keepBars[faction] = bar;
      children.add(bar);
    }
    children.add(
      RectangleComponent(
        position: Vector2(1, 1),
        size: Vector2(PixelViewport.width - 2, PixelViewport.height - 2),
        priority: 799,
        paint: Paint()
          ..color = const Color(0xFF151A15)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..isAntiAlias = false,
      ),
    );
    _selection = SelectionView();
    children.add(_selection);
    children.add(KeepCollisionView(battle));
    children.add(
      HitboxView(
        battle: battle,
        viewport: _viewport,
        keepSpriteBounds: keepSpriteBounds,
        unitViews: () => _units.values,
        visible: showHitboxes,
      ),
    );
    await addAll(children);
  }

  Rect keepSpriteBounds(Faction faction) {
    final sprite = switch (faction) {
      Faction.heretic => _hereticKeep,
      Faction.hexen => _hexenKeep,
    };
    return Rect.fromCenter(
      center: Offset(sprite.position.x, sprite.position.y),
      width: sprite.size.x,
      height: sprite.size.y,
    );
  }

  void layout() {
    if (isLoaded && _selection.isLoaded) {
      _selection.sync(selectionStart, selectionEnd, _viewport);
    }
  }

  @override
  void update(double dt) {
    for (final faction in Faction.values) {
      final health = faction == battle.playerFaction
          ? battle.playerBaseHealth
          : battle.enemyBaseHealth;
      final maximum = faction == battle.playerFaction
          ? BattleState.baseHealth
          : battle.enemyBaseMaxHealth;
      _keepBars[faction]!.setRatio(health / maximum);
    }

    final currentMana = battle.manaPowerUp;
    if (currentMana != _mana?.powerUp) {
      _mana?.removeFromParent();
      if (currentMana == null) {
        _mana = null;
      } else {
        _mana = ManaCrystalView(currentMana, _viewport, _assets);
        add(_mana!);
      }
    }
    if (_mana?.isLoaded ?? false) _mana!.sync(battle.elapsed);

    final liveIds = <int>{};
    for (final unit in battle.units) {
      liveIds.add(unit.id);
      final view = _units.putIfAbsent(unit.id, () {
        final created = UnitView(unit, _assets, _viewport, battle);
        add(created);
        return created;
      });
      if (view.isLoaded) view.sync();
    }
    for (final id in _units.keys.toList()) {
      if (liveIds.contains(id)) continue;
      _units.remove(id)?.removeFromParent();
    }

    final liveEffects = battle.attackEffects.toSet();
    for (final effect in liveEffects) {
      final sheet = _assets.projectileSheet(effect.faction);
      final component = _effects.putIfAbsent(effect, () {
        final created = _assets.projectileComponent(effect.faction);
        add(created);
        return created;
      });
      final t = effect.progress.clamp(0.0, 1.0);
      final from = _viewport.viewPoint(effect.from);
      final to = _viewport.viewPoint(effect.to);
      component.position = Vector2(
        (from.dx + (to.dx - from.dx) * t).roundToDouble(),
        (from.dy + (to.dy - from.dy) * t - 18).roundToDouble(),
      );
      component.animationTicker!.currentIndex = sheet.frameAt(t);
    }
    for (final effect in _effects.keys.toList()) {
      if (liveEffects.contains(effect)) continue;
      _effects.remove(effect)?.removeFromParent();
    }
    super.update(dt);
  }
}
