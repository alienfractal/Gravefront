import 'package:flame/components.dart';
import 'package:flame_behaviors/flame_behaviors.dart';

import '../services/battle_logic_service.dart';
import '../view/keep_hitbox_view.dart';

/// Reports Flame range/keep overlaps to the pure Dart battle rules.
class KeepContactBehavior
    extends CollisionBehavior<KeepHitboxView, PositionedEntity> {
  KeepContactBehavior(this.unit, this.battle);

  final BattleUnit unit;
  final BattleState battle;

  @override
  void onCollision(Set<Vector2> intersectionPoints, KeepHitboxView other) {
    if (other.faction != unit.faction && unit.isAlive) {
      battle.markKeepContact(unit.id);
    }
  }
}
