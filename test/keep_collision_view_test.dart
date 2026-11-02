import 'dart:math';

import 'package:flame/game.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gravefront_arena/game/states/level/services/battle_logic_service.dart';
import 'package:gravefront_arena/game/states/level/view/keep_collision_view.dart';

void main() {
  testWidgets('Flame keep collision controls keep damage', (tester) async {
    final battle = BattleState(Faction.hexen, random: Random(4));
    battle.units.removeWhere((unit) => unit.faction == Faction.heretic);
    final ettin = battle.units.single;
    ettin.attackBase = true;
    battle.enemyBaseHealth = 20;
    ettin.position = const Point(600, 310);

    final game = FlameGame();
    await tester.pumpWidget(GameWidget(game: game));
    await tester.pump();
    await tester.runAsync(game.ready);
    final collisions = KeepCollisionView(battle);
    await game.world.add(collisions);
    await tester.pump();
    await collisions.mounted;
    game.update(1 / 60);
    battle.step(1 / 60);
    expect(battle.enemyBaseHealth, 20);

    ettin.position = const Point(700, 310);
    game.update(1 / 60);
    battle.step(1 / 60);
    expect(battle.enemyBaseHealth, lessThan(20));

    final healthAfterHit = battle.enemyBaseHealth;
    ettin.position = const Point(600, 310);
    game.update(1 / 60);
    battle.step(2);
    expect(battle.enemyBaseHealth, healthAfterHit);
  });
}
