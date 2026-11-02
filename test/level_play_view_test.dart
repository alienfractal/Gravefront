import 'dart:math';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gravefront_arena/game/camera/pixel_viewport.dart';
import 'package:gravefront_arena/game/states/level/services/battle_logic_service.dart';
import 'package:gravefront_arena/game/states/level/services/level_cache_service.dart';
import 'package:gravefront_arena/game/states/level/view/level_play_view.dart';
import 'package:gravefront_arena/game/states/level/view/hitbox_view.dart';
import 'package:gravefront_arena/game/states/level/view/unit_view.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('battlefield builds and renders its sprite component tree', () async {
    final battle = BattleState(Faction.heretic);
    final assets = LevelCacheService();
    await assets.load();
    final firstTerrain = assets.terrainComponent(battle.campaignLevel.map);
    await assets.load();
    final secondTerrain = assets.terrainComponent(battle.campaignLevel.map);
    expect(identical(firstTerrain.sprite, secondTerrain.sprite), isTrue);
    expect(identical(firstTerrain, secondTerrain), isFalse);
    expect(
      assets.unitAtlas(Faction.heretic, UnitRole.champion, 'walk'),
      isA<UnitAtlas>(),
    );
    final firstKeep = assets.hereticKeep.getSpriteComponent();
    final secondKeep = assets.hereticKeep.getSpriteComponent();
    expect(identical(firstKeep, secondKeep), isFalse);
    expect(identical(firstKeep.sprite, secondKeep.sprite), isTrue);
    final view = LevelPlayView(
      battle,
      assets,
      PixelViewport(),
      showHitboxes: () => false,
    );
    final game = FlameGame();
    game.onGameResize(Vector2(320, 200));
    game.camera.viewfinder.anchor = Anchor.topLeft;
    await game.world.add(view);
    game.update(1 / 60);
    view.layout();

    expect(view.children.whereType<SpriteComponent>().length, 3);
    final hitboxes = view.children.whereType<HitboxView>().single;
    final keepArt = view.keepSpriteBounds(Faction.heretic);
    final keepHurt = hitboxes.keepHurtBounds(Faction.heretic);
    final keepOrder = hitboxes.keepOrderBounds(Faction.hexen);
    expect(keepArt.width, 83);
    expect(keepArt.height, 102);
    expect(keepHurt.width, closeTo(74, 1));
    expect(keepHurt.height, closeTo(89, 1));
    expect(keepArt.contains(keepHurt.topLeft), isTrue);
    expect(keepArt.contains(keepHurt.bottomRight), isTrue);
    expect(keepOrder.width, closeTo(83, 2));
    expect(keepOrder.height, closeTo(102, 2));
    final units = view.children.whereType<UnitView>().toList();
    expect(units.length, 2);
    await Future.wait(units.map((unit) => unit.loaded));
    final unitView = units.first;
    unitView.unit.position = const Point(400, BattleState.horizonY);
    unitView.sync();
    final distantHeight = unitView.spriteBounds.height;
    unitView.unit.position = const Point(400, BattleState.height - 25);
    unitView.sync();
    expect(unitView.spriteBounds.height, greaterThan(distantHeight));
    expect(
      units.every(
        (unit) =>
            unit.children.whereType<SpriteAnimationComponent>().length == 1,
      ),
      isTrue,
    );

    final recorder = ui.PictureRecorder();
    game.render(ui.Canvas(recorder));
    recorder.endRecording().dispose();
    await assets.dispose();
  });
}
