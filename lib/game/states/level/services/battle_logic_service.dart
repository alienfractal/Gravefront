import 'dart:math';

import '../../../model/campaign_model.dart';
import '../model/unit_model.dart';

export '../../../model/campaign_model.dart';
export '../model/unit_model.dart';

class BattleState {
  BattleState(this.playerFaction, {this.level = 1, Random? random})
    : assert(level >= 1 && level <= campaignLevels.length),
      _random = random ?? Random() {
    _nextManaPowerUpAt = 8 + _random.nextDouble() * 4;
    _spawn(playerFaction, UnitRole.melee, free: true);
    _spawn(enemyFaction, UnitRole.melee, free: true);
    if (level > 1) {
      final newRole = UnitRole.values[level - 1];
      _spawn(playerFaction, newRole, free: true);
      _spawn(enemyFaction, newRole, free: true);
    }
  }

  static const double width = 1000;
  static const double height = 620;
  // Ground begins at arena y=64 in the 320 x 160 battlefield.
  static const double horizonY = 248;
  static const double minPerspectiveScale = 0.5;
  static const double baseHealth = 480;
  // Battle-world bounds for the 83 x 102 camera-pixel keep sprite.
  static const double keepHurtHalfWidth = 115;
  static const double keepHurtAbove = 270;
  static const double keepHurtBelow = 75;
  static const double keepOrderHalfWidth = 130;
  static const double keepOrderAbove = 305;
  static const double keepOrderBelow = 90;
  static const double unitSelectHalfWidth = 75;
  static const double unitSelectAbove = 150;
  static const double unitSelectBelow = 25;
  static const double manaCap = 200;
  static const double manaRate = 2;
  static const double enemyManaRate = 2.2;
  static const double deathAnimationDuration = 1.15;
  static const double corpseDuration = 45.5;
  static const double manaPowerUpValue = 60;
  static const double manaPickupRadius = 60;

  final Faction playerFaction;
  final int level;
  final Random _random;
  final List<BattleUnit> units = [];
  final List<AttackEffect> attackEffects = [];
  final Set<int> selectedIds = {};
  final Set<int> _unitsInKeepRange = {};
  final List<BattleSoundEvent> _soundEvents = [];
  ManaPowerUp? manaPowerUp;
  late double _nextManaPowerUpAt;

  CampaignLevel get campaignLevel => campaignLevels[level - 1];
  List<UnitRole> get unlockedRoles =>
      UnitRole.values.where((role) => role.unlockLevel <= level).toList();
  double get enemyBaseMaxHealth => baseHealth + (level - 1) * 90;

  List<BattleSoundEvent> drainSoundEvents() {
    final events = List<BattleSoundEvent>.of(_soundEvents);
    _soundEvents.clear();
    return events;
  }

  late final Faction enemyFaction = playerFaction.opponent;
  double playerMana = 85;
  late double enemyMana = 95 + (level - 1) * 20;
  double playerBaseHealth = baseHealth;
  late double enemyBaseHealth = enemyBaseMaxHealth;
  double elapsed = 0;
  double _enemySpawnClock = 0;
  int _nextId = 1;
  int _enemySpawnCount = 0;
  Faction? winner;

  Point<double> basePosition(Faction faction) =>
      faction == playerFaction ? const Point(100, 310) : const Point(900, 310);

  static double perspectiveScaleAt(double y) {
    final depth = ((y - horizonY) / (height - horizonY))
        .clamp(0.0, 1.0)
        .toDouble();
    return minPerspectiveScale + (1 - minPerspectiveScale) * depth;
  }

  Rectangle<double> unitSelectionBox(BattleUnit unit) {
    final scale = perspectiveScaleAt(unit.position.y);
    return Rectangle(
      unit.position.x - unitSelectHalfWidth * scale,
      unit.position.y - unitSelectAbove * scale,
      unitSelectHalfWidth * 2 * scale,
      (unitSelectAbove + unitSelectBelow) * scale,
    );
  }

  Rectangle<double> keepHurtbox(Faction faction) {
    final center = basePosition(faction);
    return Rectangle(
      center.x - keepHurtHalfWidth,
      center.y - keepHurtAbove,
      keepHurtHalfWidth * 2,
      keepHurtAbove + keepHurtBelow,
    );
  }

  Rectangle<double> keepOrderBox(Faction faction) {
    final center = basePosition(faction);
    return Rectangle(
      center.x - keepOrderHalfWidth,
      center.y - keepOrderAbove,
      keepOrderHalfWidth * 2,
      keepOrderAbove + keepOrderBelow,
    );
  }

  /// Receives the current keep contacts from the Flame collision layer.
  void clearKeepContacts() => _unitsInKeepRange.clear();

  void markKeepContact(int unitId) => _unitsInKeepRange.add(unitId);

  Point<double> nearestKeepPoint(Point<double> from, Faction faction) {
    final box = keepHurtbox(faction);
    return Point(
      from.x.clamp(box.left, box.right).toDouble(),
      from.y.clamp(box.top, box.bottom).toDouble(),
    );
  }

  bool spawnPlayer(UnitRole role) =>
      role.unlockLevel <= level && _spawn(playerFaction, role);

  bool _spawn(Faction faction, UnitRole role, {bool free = false}) {
    if (winner != null || role.unlockLevel > level) return false;
    final stats = statsFor(faction, role);
    final available = faction == playerFaction ? playerMana : enemyMana;
    if (!free && available < stats.cost) return false;
    if (!free) {
      if (faction == playerFaction) {
        playerMana -= stats.cost;
      } else {
        enemyMana -= stats.cost;
      }
    }
    final base = basePosition(faction);
    final side = faction == playerFaction ? 1.0 : -1.0;
    final offset = (_random.nextDouble() - 0.5) * 90;
    final spawnDistance = role.usesProjectile ? 205.0 : 240.0;
    final spawnY = base.y + (role.usesProjectile ? 170 : 0) + offset;
    final unit = BattleUnit(
      _nextId++,
      faction,
      role,
      Point(base.x + side * spawnDistance, spawnY.clamp(horizonY, height - 35)),
    );
    unit.attackBase = faction != playerFaction;
    unit.facing = faction == playerFaction ? 7 : 3;
    units.add(unit);
    if (!free) {
      _soundEvents.add(BattleSoundEvent(BattleSound.summon, faction, role));
    }
    return true;
  }

  void step(double dt) {
    if (winner != null) return;
    for (final effect in attackEffects) {
      effect.timeLeft -= dt;
    }
    attackEffects.removeWhere((effect) => effect.timeLeft <= 0);
    elapsed += dt;
    playerMana = min(manaCap, playerMana + manaRate * dt);
    enemyMana = min(
      manaCap,
      enemyMana + (enemyManaRate + (level - 1) * 0.7) * dt,
    );
    _enemySpawnClock += dt;
    if (_enemySpawnClock >= campaignLevel.enemySpawnSeconds) {
      _enemySpawnClock -= campaignLevel.enemySpawnSeconds;
      final roles = unlockedRoles;
      final role = roles[_enemySpawnCount % roles.length];
      if (_spawn(enemyFaction, role)) _enemySpawnCount++;
    }

    for (final unit in List<BattleUnit>.of(units)) {
      if (!unit.isAlive) {
        unit.deathTime += dt;
        continue;
      }
      if (winner != null) break;
      unit.walking = false;
      unit.attackCooldown = max(0, unit.attackCooldown - dt);
      unit.attackAnimationTime = max(0, unit.attackAnimationTime - dt);
      unit.hitFlash = max(0, unit.hitFlash - dt);
      _stepUnit(unit, dt);
    }
    _stepManaPowerUp(dt);
    units.removeWhere(
      (unit) => !unit.isAlive && unit.deathTime >= corpseDuration,
    );
    selectedIds.removeWhere(
      (id) => !units.any((unit) => unit.id == id && unit.isAlive),
    );
  }

  void _stepManaPowerUp(double dt) {
    final active = manaPowerUp;
    if (active != null) {
      active.timeLeft -= dt;
      if (active.timeLeft <= 0) {
        manaPowerUp = null;
      } else {
        for (final unit in units) {
          if (unit.faction == playerFaction &&
              unit.isAlive &&
              unit.position.distanceTo(active.position) <= manaPickupRadius) {
            playerMana = min(manaCap, playerMana + active.value);
            unit.destination = null;
            manaPowerUp = null;
            break;
          }
        }
      }
    }
    if (manaPowerUp == null && elapsed >= _nextManaPowerUpAt) {
      manaPowerUp = ManaPowerUp(
        Point(
          270 + _random.nextDouble() * 300,
          horizonY + 20 + _random.nextDouble() * (480 - horizonY - 20),
        ),
        manaPowerUpValue,
      );
      _nextManaPowerUpAt = elapsed + 14 + _random.nextDouble() * 9;
    }
  }

  void _stepUnit(BattleUnit unit, double dt) {
    final stats = unit.stats;
    final crystal = manaPowerUp;
    final destination = unit.destination;
    if (unit.faction == playerFaction &&
        crystal != null &&
        destination != null &&
        destination.distanceTo(crystal.position) < 1) {
      if (unit.position.distanceTo(crystal.position) > manaPickupRadius / 2) {
        _moveToward(unit, crystal.position, dt);
      }
      return;
    }
    BattleUnit? target;
    if (unit.targetUnitId case final int id) {
      for (final candidate in units) {
        if (candidate.id == id &&
            candidate.isAlive &&
            candidate.faction != unit.faction) {
          target = candidate;
          break;
        }
      }
      if (target == null) unit.targetUnitId = null;
    }
    target ??= _nearestEnemy(unit, stats.range + 65);
    if (target != null) {
      final distance = unit.position.distanceTo(target.position);
      if (distance > stats.range + 17) {
        _moveToward(unit, target.position, dt);
      } else if (unit.attackCooldown <= 0) {
        _face(unit, target.position);
        target.health -= stats.damage;
        target.hitFlash = 0.18;
        _soundEvents.add(
          BattleSoundEvent(
            target.isAlive ? BattleSound.hurt : BattleSound.death,
            target.faction,
            target.role,
          ),
        );
        _startAttackAnimation(unit, target.position);
        unit.attackCooldown = stats.attackDelay;
      }
      return;
    }

    if (unit.destination case final Point<double> destination) {
      if (unit.position.distanceTo(destination) > 5) {
        _moveToward(unit, destination, dt);
      } else {
        unit.destination = null;
      }
      return;
    }

    if (unit.attackBase) {
      final targetFaction = unit.faction.opponent;
      final enemyBase = basePosition(targetFaction);
      final contact = nearestKeepPoint(unit.position, targetFaction);
      if (!_unitsInKeepRange.contains(unit.id)) {
        _moveToward(unit, contact, dt);
      } else if (unit.attackCooldown <= 0) {
        _face(unit, enemyBase);
        _startAttackAnimation(unit, enemyBase);
        if (unit.faction == playerFaction) {
          enemyBaseHealth = max(0, enemyBaseHealth - stats.damage);
          if (enemyBaseHealth == 0) winner = playerFaction;
        } else {
          playerBaseHealth = max(0, playerBaseHealth - stats.damage);
          if (playerBaseHealth == 0) winner = unit.faction;
        }
        unit.attackCooldown = stats.attackDelay;
      }
    }
  }

  void _startAttackAnimation(BattleUnit unit, Point<double> target) {
    unit.attackAnimationTime = 0.42;
    _soundEvents.add(
      BattleSoundEvent(BattleSound.attack, unit.faction, unit.role),
    );
    if (unit.role.usesProjectile) {
      attackEffects.add(AttackEffect(unit.position, target, unit.faction));
    }
  }

  BattleUnit? _nearestEnemy(BattleUnit unit, double radius) {
    BattleUnit? nearest;
    var nearestDistance = radius;
    for (final candidate in units) {
      if (!candidate.isAlive || candidate.faction == unit.faction) continue;
      final distance = unit.position.distanceTo(candidate.position);
      if (distance < nearestDistance) {
        nearest = candidate;
        nearestDistance = distance;
      }
    }
    return nearest;
  }

  void _moveToward(BattleUnit unit, Point<double> target, double dt) {
    final targetY = target.y.clamp(horizonY, height - 25);
    final dx = target.x - unit.position.x;
    final dy = targetY - unit.position.y;
    final distance = sqrt(dx * dx + dy * dy);
    if (distance < 0.001) return;
    _face(unit, target);
    final step = min(unit.stats.speed * dt, distance);
    unit.position = Point(
      (unit.position.x + dx / distance * step).clamp(20.0, width - 20),
      (unit.position.y + dy / distance * step).clamp(horizonY, height - 25),
    );
    unit.walking = true;
    unit.walkClock += dt;
  }

  void _face(BattleUnit unit, Point<double> target) {
    final dx = target.x - unit.position.x;
    final dy = target.y - unit.position.y;
    if (dx.abs() + dy.abs() < 0.001) return;
    final octant = (atan2(dy, dx) / (pi / 4)).round();
    // Doom rotation 1 faces down, 3 left, 5 up, and 7 right.
    unit.facing = (octant + 6) % 8 + 1;
  }

  void selectPoint(Point<double> point, {bool add = false}) {
    if (!add) selectedIds.clear();
    BattleUnit? nearest;
    var bestScore = double.infinity;
    for (final unit in units) {
      if (unit.faction != playerFaction || !unit.isAlive) continue;
      final dx = (unit.position.x - point.x).abs();
      final dy = unit.position.y - point.y;
      if (unitSelectionBox(unit).containsPoint(point)) {
        final score = dx + dy.abs() * 0.4;
        if (score >= bestScore) continue;
        bestScore = score;
        nearest = unit;
      }
    }
    if (nearest != null) selectedIds.add(nearest.id);
  }

  void selectBox(Point<double> a, Point<double> b, {bool add = false}) {
    if (!add) selectedIds.clear();
    final left = min(a.x, b.x);
    final right = max(a.x, b.x);
    final top = min(a.y, b.y);
    final bottom = max(a.y, b.y);
    for (final unit in units) {
      final box = unitSelectionBox(unit);
      if (unit.faction == playerFaction &&
          unit.isAlive &&
          box.right >= left &&
          box.left <= right &&
          box.bottom >= top &&
          box.top <= bottom) {
        selectedIds.add(unit.id);
      }
    }
  }

  void issueCommand(Point<double> point) {
    if (selectedIds.isEmpty || winner != null) return;
    final crystal = manaPowerUp;
    if (crystal != null && point.distanceTo(crystal.position) < 75) {
      for (final unit in units) {
        if (!unit.isAlive || !selectedIds.contains(unit.id)) continue;
        unit.targetUnitId = null;
        unit.attackBase = false;
        unit.destination = crystal.position;
      }
      return;
    }
    BattleUnit? target;
    var bestScore = double.infinity;
    for (final unit in units) {
      if (unit.faction != enemyFaction || !unit.isAlive) continue;
      final dx = (unit.position.x - point.x).abs();
      final dy = unit.position.y - point.y;
      if (!unitSelectionBox(unit).containsPoint(point)) {
        continue;
      }
      final score = dx + dy.abs() * 0.4;
      if (score >= bestScore) continue;
      bestScore = score;
      target = unit;
    }
    final attackBase =
        target == null && keepOrderBox(enemyFaction).containsPoint(point);
    final selected = units
        .where((unit) => unit.isAlive && selectedIds.contains(unit.id))
        .toList();
    final columns = min(3, selected.length);
    for (var i = 0; i < selected.length; i++) {
      final unit = selected[i];
      unit.targetUnitId = target?.id;
      unit.attackBase = attackBase;
      if (target == null && !attackBase) {
        final col = i % 3;
        final row = i ~/ 3;
        unit.destination = Point(
          (point.x + (col - (columns - 1) / 2) * 135).clamp(20.0, width - 20),
          (point.y + row * 120).clamp(horizonY, height - 25),
        );
      } else {
        unit.destination = null;
      }
    }
  }
}
