import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:gravefront_arena/game/states/level/services/battle_logic_service.dart';
import 'package:gravefront_arena/audio/game_audio_service.dart';
import 'package:gravefront_arena/gen/assets.gen.dart';

void main() {
  test('selected units follow orders while enemy units do not', () {
    final battle = BattleState(Faction.heretic, random: Random(3));
    final friendly = battle.units.first;
    final enemy = battle.units.firstWhere(
      (unit) => unit.faction == Faction.hexen,
    );
    final enemyStart = enemy.position;
    final friendlyStart = friendly.position;

    battle.step(0.5);
    expect(friendly.position, friendlyStart);
    expect(enemy.position.x, lessThan(enemyStart.x));

    battle.selectPoint(friendly.position);
    battle.issueCommand(const Point(430, 160));
    battle.step(0.5);

    expect(battle.selectedIds, contains(friendly.id));
    expect(friendly.position.x, greaterThan(friendlyStart.x));
    expect(enemy.destination, isNull);
  });

  test('an ordered attack ends the match when the enemy keep falls', () {
    final battle = BattleState(Faction.hexen, random: Random(4));
    battle.units.removeWhere((unit) => unit.faction == Faction.heretic);
    final ettin = battle.units.firstWhere(
      (unit) => unit.role == UnitRole.melee,
    );
    ettin.position = const Point(700, 310);
    battle.enemyBaseHealth = 5;

    battle.selectPoint(ettin.position);
    battle.issueCommand(const Point(780, 310));
    battle.markKeepContact(ettin.id);
    battle.step(0.1);

    expect(battle.winner, Faction.hexen);
    expect(battle.enemyBaseHealth, 0);
    expect(ettin.attackAnimationTime, greaterThan(0));
  });

  test('a defeated battle stops advancing until the level is retried', () {
    final battle = BattleState(Faction.heretic, random: Random(12));
    battle.units.removeWhere((unit) => unit.faction == Faction.heretic);
    final enemy = battle.units.single;
    enemy.position = const Point(290, 310);
    battle.playerBaseHealth = 1;

    battle.markKeepContact(enemy.id);
    battle.step(0.1);
    expect(battle.winner, Faction.hexen);
    final elapsed = battle.elapsed;
    final enemyPosition = enemy.position;
    final mana = battle.playerMana;

    battle.step(10);
    expect(battle.elapsed, elapsed);
    expect(enemy.position, enemyPosition);
    expect(battle.playerMana, mana);
    expect(battle.winner, Faction.hexen);
  });

  test('keep hit and click areas follow the visible keep footprint', () {
    final battle = BattleState(Faction.heretic, random: Random(19));
    battle.units.removeWhere((unit) => unit.faction == Faction.hexen);
    final golem = battle.units.first;
    final hurt = battle.keepHurtbox(Faction.hexen);
    final click = battle.keepOrderBox(Faction.hexen);

    expect(hurt.width, 230);
    expect(hurt.height, 345);
    expect(click.width, 260);
    expect(click.height, 395);
    expect(
      battle.nearestKeepPoint(const Point(500, 310), Faction.hexen),
      const Point(785, 310),
    );

    battle.selectPoint(golem.position);
    battle.issueCommand(const Point(780, 310));
    expect(golem.attackBase, isTrue);
    expect(golem.destination, isNull);
  });

  test('a ranged attack starts its pose and projectile effect', () {
    final battle = BattleState(Faction.hexen, level: 2, random: Random(5));
    battle.units.removeWhere((unit) => unit.faction == Faction.heretic);
    final afrit = battle.units.firstWhere(
      (unit) => unit.role == UnitRole.ranged,
    );
    afrit.position = const Point(600, 310);

    battle.selectPoint(afrit.position);
    battle.issueCommand(battle.basePosition(Faction.heretic));
    battle.markKeepContact(afrit.id);
    battle.step(0.1);

    expect(afrit.attackAnimationTime, greaterThan(0));
    expect(battle.attackEffects, hasLength(1));
    expect(battle.attackEffects.single.faction, Faction.hexen);
    battle.step(0.3);
    expect(battle.attackEffects, isEmpty);
  });

  test('movement and attack orders choose directional sprite rotations', () {
    final battle = BattleState(Faction.heretic, random: Random(6));
    battle.units.removeWhere((unit) => unit.faction == Faction.hexen);
    final golem = battle.units.first;
    golem.position = const Point(400, 310);
    battle.selectPoint(golem.position);

    battle.issueCommand(const Point(400, 150));
    battle.step(0.1);
    expect(golem.facing, 5); // Up / back.

    golem.position = const Point(400, 310);
    battle.issueCommand(const Point(600, 310));
    battle.step(0.1);
    expect(golem.facing, 7); // Right.

    golem.position = const Point(400, 310);
    battle.issueCommand(const Point(200, 310));
    battle.step(0.1);
    expect(golem.facing, 3); // Left.
  });

  test('unit art can be selected and targeted above its feet', () {
    final battle = BattleState(Faction.heretic, random: Random(11));
    final golem = battle.units.firstWhere(
      (unit) => unit.faction == Faction.heretic && unit.role == UnitRole.melee,
    );
    final ettin = battle.units.firstWhere(
      (unit) => unit.faction == Faction.hexen && unit.role == UnitRole.melee,
    );

    battle.selectPoint(Point(golem.position.x, golem.position.y - 60));
    expect(battle.selectedIds, contains(golem.id));

    battle.issueCommand(Point(ettin.position.x, ettin.position.y - 60));
    expect(golem.targetUnitId, ettin.id);
  });

  test('units shrink toward the horizon and cannot walk into the sky', () {
    expect(
      BattleState.perspectiveScaleAt(BattleState.horizonY),
      BattleState.minPerspectiveScale,
    );
    expect(BattleState.perspectiveScaleAt(BattleState.height), 1);
    final battle = BattleState(Faction.heretic, random: Random(23));
    battle.units.removeWhere((unit) => unit.faction == Faction.hexen);
    final golem = battle.units.single;
    golem.position = const Point(400, 310);
    battle.selectPoint(golem.position);
    battle.issueCommand(const Point(400, 0));

    expect(golem.destination!.y, BattleState.horizonY);
    battle.step(2);
    expect(golem.position.y, BattleState.horizonY);
    battle.step(1);
    expect(golem.destination, isNull);
  });

  test('selection follows a unit as its visible size changes', () {
    final battle = BattleState(Faction.heretic, random: Random(24));
    final golem = battle.units.firstWhere(
      (unit) => unit.faction == Faction.heretic,
    );
    golem.position = const Point(400, BattleState.horizonY);
    battle.selectPoint(const Point(400, BattleState.horizonY - 100));
    expect(battle.selectedIds, isEmpty);

    golem.position = const Point(400, BattleState.height - 25);
    battle.selectPoint(const Point(400, BattleState.height - 125));
    expect(battle.selectedIds, contains(golem.id));
  });

  test('dead units play their death sequence before leaving the field', () {
    final battle = BattleState(Faction.heretic, random: Random(7));
    final golem = battle.units.first;
    battle.selectPoint(golem.position);
    golem.health = 0;

    battle.step(0.5);
    expect(battle.units, contains(golem));
    expect(golem.deathTime, 0.5);
    expect(battle.selectedIds, isEmpty);

    battle.step(BattleState.corpseDuration);
    expect(battle.units, isNot(contains(golem)));
  });

  test('combat emits matching attack and death sound cues', () {
    final battle = BattleState(Faction.heretic, random: Random(8));
    final golem = battle.units.first;
    final ettin = battle.units.firstWhere(
      (unit) => unit.faction == Faction.hexen && unit.role == UnitRole.melee,
    );
    battle.units.removeWhere((unit) => unit != golem && unit != ettin);
    golem.position = const Point(400, 310);
    ettin.position = const Point(425, 310);
    ettin.health = golem.stats.damage;

    battle.step(0.1);
    final cues = battle.drainSoundEvents().map(soundAssetPathFor).toList();

    expect(cues, contains(Assets.audio.golemAttackWav));
    expect(cues, contains(Assets.audio.ettinDeathWav));
    expect(cues, isNot(contains(Assets.audio.ettinHurtWav)));
    expect(battle.drainSoundEvents(), isEmpty);
  });

  test('five levels unlock one new unit tier per faction', () {
    expect(campaignLevels, hasLength(5));
    for (var level = 1; level <= campaignLevels.length; level++) {
      final battle = BattleState(
        Faction.heretic,
        level: level,
        random: Random(level),
      );
      final newRole = UnitRole.values[level - 1];

      expect(battle.unlockedRoles, hasLength(level));
      expect(battle.unlockedRoles.last, newRole);
      expect(
        battle.units.any(
          (unit) => unit.faction == Faction.heretic && unit.role == newRole,
        ),
        isTrue,
      );
      expect(
        battle.units.any(
          (unit) => unit.faction == Faction.hexen && unit.role == newRole,
        ),
        isTrue,
      );
      battle.playerMana = BattleState.manaCap;
      expect(battle.spawnPlayer(newRole), isTrue);
      if (level < campaignLevels.length) {
        expect(battle.spawnPlayer(UnitRole.values[level]), isFalse);
      }
    }
    expect(
      campaignLevels.last.enemySpawnSeconds,
      lessThan(campaignLevels.first.enemySpawnSeconds),
    );
  });

  test('a random mana crystal grants mana when a player unit reaches it', () {
    final battle = BattleState(Faction.heretic, level: 3, random: Random(21));
    battle.units.removeWhere((unit) => unit.faction == Faction.hexen);
    battle.enemyMana = 0;
    for (var i = 0; i < 900 && battle.manaPowerUp == null; i++) {
      battle.step(1 / 60);
    }
    final crystal = battle.manaPowerUp;
    expect(crystal, isNotNull);
    expect(crystal!.position.y, greaterThan(BattleState.horizonY));

    battle.playerMana = 0;
    battle.units.first.position = crystal.position;
    battle.step(1 / 60);

    expect(battle.manaPowerUp, isNull);
    expect(
      battle.playerMana,
      greaterThanOrEqualTo(BattleState.manaPowerUpValue),
    );
  });

  test('a crystal order moves through combat and collects the mana', () {
    final battle = BattleState(Faction.heretic, random: Random(22));
    final golem = battle.units.firstWhere(
      (unit) => unit.faction == Faction.heretic,
    );
    final ettin = battle.units.firstWhere(
      (unit) => unit.faction == Faction.hexen,
    );
    golem.position = const Point(400, 310);
    ettin.position = const Point(420, 310);
    final ettinHealth = ettin.health;
    battle.playerMana = 0;
    battle.manaPowerUp = ManaPowerUp(const Point(500, 310), 60);

    battle.selectPoint(golem.position);
    battle.issueCommand(const Point(500, 310));
    battle.step(0.2);

    expect(golem.position.x, greaterThan(400));
    expect(ettin.health, ettinHealth);
    for (var i = 0; i < 20 && battle.manaPowerUp != null; i++) {
      battle.step(0.2);
    }
    expect(battle.manaPowerUp, isNull);
    expect(battle.playerMana, greaterThanOrEqualTo(60));
  });
}
