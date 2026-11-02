import 'dart:math';
import 'dart:ui';

import '../services/battle_logic_service.dart';
import '../services/level_cache_service.dart';

/// Chooses presentation frames from simulation state; it never advances combat.
class UnitAnimationHandler {
  const UnitAnimationHandler();

  double scaleFor(BattleUnit unit) =>
      BattleState.perspectiveScaleAt(unit.position.y);

  String stateFor(BattleUnit unit) => !unit.isAlive
      ? 'death'
      : unit.attackAnimationTime > 0
      ? 'attack'
      : 'walk';

  int frameFor(BattleUnit unit, String name, String state, UnitAtlas atlas) =>
      switch (state) {
        'death' => min(
          atlas.frameCount - 1,
          (unit.deathTime /
                  BattleState.deathAnimationDuration *
                  atlas.frameCount)
              .floor(),
        ),
        'attack' => min(
          atlas.frameCount - 1,
          ((1 - unit.attackAnimationTime / 0.42) * atlas.frameCount).floor(),
        ),
        _ =>
          unit.walking
              ? (unit.walkClock * 7).floor() % atlas.frameCount
              : name == 'gargoyle'
              ? 2
              : 0,
      };

  double heightFor(UnitRole role, String name) => switch (role) {
    UnitRole.melee => 42.0,
    UnitRole.ranged => name == 'gargoyle' ? 41.0 : 40.0,
    UnitRole.heavy => 44.0,
    UnitRole.caster => 41.0,
    UnitRole.champion => 43.0,
  };

  Rect destinationRect(
    Offset feet,
    UnitAtlas walkAtlas,
    UnitAtlas atlas,
    double baseHeight,
  ) {
    final imageScale = baseHeight / walkAtlas.cellHeight;
    final height = (atlas.cellHeight * imageScale).roundToDouble();
    final width = (atlas.cellWidth * imageScale).roundToDouble();
    return Rect.fromLTWH(
      (feet.dx - width / 2).roundToDouble(),
      (feet.dy - height + 5).roundToDouble(),
      width,
      height,
    );
  }
}
