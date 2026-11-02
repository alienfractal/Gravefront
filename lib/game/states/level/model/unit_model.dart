import 'dart:math';

enum Faction { heretic, hexen }

enum UnitRole { melee, ranged, heavy, caster, champion }

extension UnitRoleRules on UnitRole {
  int get unlockLevel => index + 1;
  bool get usesProjectile =>
      this == UnitRole.ranged ||
      this == UnitRole.caster ||
      this == UnitRole.champion;
}

String assetNameFor(Faction faction, UnitRole role) =>
    switch ((faction, role)) {
      (Faction.heretic, UnitRole.melee) => 'golem',
      (Faction.heretic, UnitRole.ranged) => 'gargoyle',
      (Faction.heretic, UnitRole.heavy) => 'knight',
      (Faction.heretic, UnitRole.caster) => 'ophidian',
      (Faction.heretic, UnitRole.champion) => 'lich',
      (Faction.hexen, UnitRole.melee) => 'ettin',
      (Faction.hexen, UnitRole.ranged) => 'afrit',
      (Faction.hexen, UnitRole.heavy) => 'centaur',
      (Faction.hexen, UnitRole.caster) => 'bishop',
      (Faction.hexen, UnitRole.champion) => 'serpent',
    };

enum BattleSound { summon, attack, hurt, death }

class BattleSoundEvent {
  const BattleSoundEvent(this.sound, this.faction, this.role);

  final BattleSound sound;
  final Faction faction;
  final UnitRole role;
}

extension FactionName on Faction {
  String get label => this == Faction.heretic ? 'Heretic' : 'Hexen';
  Faction get opponent =>
      this == Faction.heretic ? Faction.hexen : Faction.heretic;
}

class UnitStats {
  const UnitStats(
    this.name,
    this.cost,
    this.maxHealth,
    this.damage,
    this.speed,
    this.range,
    this.attackDelay,
  );

  final String name;
  final int cost;
  final double maxHealth;
  final double damage;
  final double speed;
  final double range;
  final double attackDelay;
}

UnitStats statsFor(Faction faction, UnitRole role) {
  return switch ((faction, role)) {
    (Faction.heretic, UnitRole.melee) => const UnitStats(
      'Golem',
      35,
      72,
      12,
      58,
      100,
      0.95,
    ),
    (Faction.heretic, UnitRole.ranged) => const UnitStats(
      'Gargoyle',
      50,
      42,
      8,
      76,
      220,
      1.15,
    ),
    (Faction.heretic, UnitRole.heavy) => const UnitStats(
      'Undead Knight',
      75,
      115,
      20,
      49,
      110,
      1.2,
    ),
    (Faction.heretic, UnitRole.caster) => const UnitStats(
      'Ophidian',
      95,
      65,
      16,
      53,
      255,
      1.35,
    ),
    (Faction.heretic, UnitRole.champion) => const UnitStats(
      'Iron Lich',
      135,
      105,
      25,
      45,
      275,
      1.65,
    ),
    (Faction.hexen, UnitRole.melee) => const UnitStats(
      'Ettin',
      35,
      78,
      11,
      56,
      100,
      0.95,
    ),
    (Faction.hexen, UnitRole.ranged) => const UnitStats(
      'Afrit',
      50,
      40,
      9,
      76,
      220,
      1.2,
    ),
    (Faction.hexen, UnitRole.heavy) => const UnitStats(
      'Centaur',
      75,
      125,
      18,
      52,
      110,
      1.2,
    ),
    (Faction.hexen, UnitRole.caster) => const UnitStats(
      'Bishop',
      95,
      68,
      16,
      54,
      255,
      1.35,
    ),
    (Faction.hexen, UnitRole.champion) => const UnitStats(
      'Chaos Serpent',
      135,
      115,
      24,
      48,
      275,
      1.65,
    ),
  };
}

class BattleUnit {
  BattleUnit(this.id, this.faction, this.role, this.position)
    : health = statsFor(faction, role).maxHealth;

  final int id;
  final Faction faction;
  final UnitRole role;
  Point<double> position;
  double health;
  double attackCooldown = 0;
  double attackAnimationTime = 0;
  double hitFlash = 0;
  double walkClock = 0;
  double deathTime = 0;
  bool walking = false;
  int facing = 1;
  Point<double>? destination;
  int? targetUnitId;
  bool attackBase = true;

  UnitStats get stats => statsFor(faction, role);
  bool get isAlive => health > 0;
  bool get isMoving =>
      destination != null || targetUnitId != null || attackBase;
}

class AttackEffect {
  AttackEffect(this.from, this.to, this.faction);

  static const double duration = 0.28;
  final Point<double> from;
  final Point<double> to;
  final Faction faction;
  double timeLeft = duration;

  double get progress => 1 - timeLeft / duration;
}

class ManaPowerUp {
  ManaPowerUp(this.position, this.value);

  final Point<double> position;
  final double value;
  double timeLeft = 12;
}
