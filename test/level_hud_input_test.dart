import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gravefront_arena/game/model/campaign_model.dart';
import 'package:gravefront_arena/game/states/level/model/unit_model.dart';
import 'package:gravefront_arena/game/states/level/services/level_cache_service.dart';
import 'package:gravefront_arena/gamefsm/campaign_fsm.dart';
import 'package:gravefront_arena/gravefront_arena_game.dart';

void main() {
  test('HUD clicks do not consume pending move orders', () {
    final game = RtsGame(
      Faction.heretic,
      assets: LevelCacheService(),
      flow: CampaignFsm(CampaignModel()),
      onMenu: () {},
      onAdvance: () {},
      onRetry: () {},
    );
    game.onGameResize(Vector2(1230, 662));
    game.moveMode = true;

    game.pointerDown(const Offset(615, 20));
    expect(game.moveMode, isTrue);

    game.pointerDown(const Offset(20, 331));
    expect(game.moveMode, isTrue);

    game.pointerDown(const Offset(615, 331));
    expect(game.moveMode, isFalse);
  });
}
