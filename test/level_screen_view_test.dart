import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gravefront_arena/game/states/level/services/battle_logic_service.dart';
import 'package:gravefront_arena/game/states/level/services/level_cache_service.dart';
import 'package:gravefront_arena/game/states/level/view/level_screen_view.dart';
import 'package:gravefront_arena/gamefsm/campaign_fsm.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'Flame HUD scales with the arena and renders the result control',
    () async {
      final battle = BattleState(Faction.heretic);
      final flow = CampaignFsm(CampaignModel())..start(Faction.heretic);
      final assets = LevelCacheService();
      await assets.load();
      final view = LevelScreenView(
        battle: battle,
        flow: flow,
        assets: assets,
        onMenu: () {},
        onAdvance: () {},
        onRetry: () {},
        onSound: () {},
        onSpawn: (_) => true,
        onOrderMode: () {},
        soundEnabled: () => true,
        orderMode: () => false,
        showHitboxes: () => false,
      );
      final game = FlameGame(
        camera: CameraComponent.withFixedResolution(width: 320, height: 200),
      );
      game.onGameResize(Vector2(1280, 800));
      await game.camera.viewport.add(view);
      game.update(1 / 60);

      expect(view.position, Vector2.zero());
      expect(view.scale, Vector2.all(1));
      expect(game.camera.viewport.virtualSize, Vector2(320, 200));
      expect(game.camera.viewport.size, Vector2(1280, 800));
      expect(view.children.whereType<HudButton>().length, 5);
      expect(
        view.children
            .whereType<HudButton>()
            .where((button) => button.visible)
            .length,
        4,
      );

      battle.winner = Faction.heretic;
      flow.finish(Faction.heretic);
      game.update(1 / 60);
      expect(
        view.children.whereType<HudButton>().any(
          (button) => button.visible && button.label == 'NEXT LEVEL',
        ),
        isTrue,
      );
      final recorder = ui.PictureRecorder();
      game.render(ui.Canvas(recorder));
      recorder.endRecording().dispose();
      await assets.dispose();
    },
  );
}
