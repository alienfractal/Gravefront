import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gravefront_arena/game/states/level/model/unit_model.dart';
import 'package:gravefront_arena/game/states/level/services/level_cache_service.dart';
import 'package:gravefront_arena/game/states/main_menu/view/main_menu_view.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'menu renders under the fixed Flame camera with faction hit targets',
    () async {
      final cache = LevelCacheService();
      final game = MainMenuGame(cache: cache, onStart: (_) {});
      game.onGameResize(Vector2(1280, 800));
      await game.onLoad();

      final menu = game.camera.viewport.children
          .whereType<MainMenuView>()
          .single;
      expect(game.camera.viewport.virtualSize, Vector2(320, 200));
      expect(menu.children.whereType<SpriteComponent>().length, 1);
      expect(menu.children.whereType<TapCallbacks>().length, 2);

      final recorder = ui.PictureRecorder();
      game.render(ui.Canvas(recorder));
      recorder.endRecording().dispose();
      await cache.dispose();
    },
  );

  testWidgets('a Flame faction card starts that faction', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final cache = LevelCacheService();
    addTearDown(cache.dispose);
    await tester.runAsync(cache.load);
    final selected = <Faction>[];
    final game = MainMenuGame(cache: cache, onStart: selected.add);
    await tester.pumpWidget(GameWidget(game: game));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.runAsync(game.ready);
    await tester.pump();
    await tester.pump();
    expect(
      tester.getSize(find.byWidgetPredicate((widget) => widget is GameWidget)),
      const Size(1280, 800),
    );
    expect(game.camera.viewport.size, Vector2(1280, 800));
    expect(game.camera.viewport.children.whereType<MainMenuView>().length, 1);
    final menu = game.camera.viewport.children.whereType<MainMenuView>().single;
    final hereticCard = menu.children.whereType<TapCallbacks>().first;
    expect(
      game.componentsAtPoint(Vector2(335, 480)).contains(hereticCard),
      isTrue,
    );
    final gesture = await tester.startGesture(const Offset(335, 480));
    await tester.pump();
    await gesture.up();
    await tester.pump(const Duration(milliseconds: 100));
    expect(selected, [Faction.heretic]);
  });
}
