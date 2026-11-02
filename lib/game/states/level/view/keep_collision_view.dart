import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame_behaviors/flame_behaviors.dart';

import '../behaviours/keep_contact_behavior.dart';
import '../services/battle_logic_service.dart';
import 'keep_hitbox_view.dart';

/// Flame collision sensors in battle-world coordinates, independent of art scale.
class KeepCollisionView extends PositionComponent with HasCollisionDetection {
  KeepCollisionView(this.battle);

  final BattleState battle;
  final Map<int, _UnitKeepRange> _unitRanges = {};

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    for (final faction in Faction.values) {
      final box = battle.keepHurtbox(faction);
      final keep = KeepHitboxView(faction)
        ..position = Vector2(box.left, box.top);
      await keep.add(
        RectangleHitbox(
          size: Vector2(box.width, box.height),
          isSolid: true,
          collisionType: CollisionType.active,
        ),
      );
      await add(keep);
    }
    for (final unit in battle.units.where((unit) => unit.isAlive)) {
      final range = _UnitKeepRange(unit, battle)
        ..position = Vector2(unit.position.x, unit.position.y);
      _unitRanges[unit.id] = range;
      await add(range);
    }
  }

  @override
  void update(double dt) {
    battle.clearKeepContacts();
    final liveIds = <int>{};
    for (final unit in battle.units.where((unit) => unit.isAlive)) {
      liveIds.add(unit.id);
      final range = _unitRanges.putIfAbsent(unit.id, () {
        final created = _UnitKeepRange(unit, battle);
        add(created);
        return created;
      });
      range.position = Vector2(unit.position.x, unit.position.y);
    }
    for (final id in _unitRanges.keys.toList()) {
      if (liveIds.contains(id)) continue;
      _unitRanges.remove(id)?.removeFromParent();
    }
    super.update(dt);
  }
}

class _UnitKeepRange extends PositionedEntity {
  _UnitKeepRange(this.unit, this.battle);

  final BattleUnit unit;
  final BattleState battle;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    await add(KeepContactBehavior(unit, battle));
    await add(
      PropagatingCollisionBehavior(
        CircleHitbox(
          radius: unit.stats.range,
          anchor: Anchor.center,
          collisionType: CollisionType.passive,
        ),
      ),
    );
  }
}
