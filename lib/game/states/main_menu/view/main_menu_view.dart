import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';

import '../../../camera/pixel_viewport.dart';
import '../../../model/campaign_model.dart';
import '../../../states/level/model/unit_model.dart';
import '../../../states/level/services/level_cache_service.dart';
import '../../../view/retro_theme.dart';

/// The menu uses the same fixed camera and cached art as the battle screens.
class MainMenuGame extends FlameGame {
  MainMenuGame({required LevelCacheService cache, required this.onStart})
    : _cache = cache,
      super(
        camera: CameraComponent.withFixedResolution(
          width: PixelViewport.cameraWidth,
          height: PixelViewport.cameraHeight,
        ),
      ) {
    camera.viewfinder.anchor = Anchor.topLeft;
  }

  final LevelCacheService _cache;
  final void Function(Faction) onStart;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    await _cache.load();
    await camera.viewport.add(MainMenuView(_cache, onStart));
  }
}

class MainMenuView extends PositionComponent {
  MainMenuView(this.assets, this.onStart)
    : super(
        size: Vector2(PixelViewport.cameraWidth, PixelViewport.cameraHeight),
      );

  final LevelCacheService assets;
  final void Function(Faction) onStart;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    await addAll([
      assets.terrainComponent(BattlefieldArt.battlefield)
        ..size = Vector2(PixelViewport.cameraWidth, PixelViewport.cameraHeight),
      _MenuBackdrop(),
      _FactionCard(
        Faction.heretic,
        assets,
        onStart,
        position: Vector2(12, 64),
        accent: const ui.Color(0xFFB77542),
        subtitle: 'GOLEM TO IRON LICH',
      ),
      _FactionCard(
        Faction.hexen,
        assets,
        onStart,
        position: Vector2(165, 64),
        accent: const ui.Color(0xFF668FBB),
        subtitle: 'ETTIN TO CHAOS SERPENT',
      ),
    ]);
  }
}

class _MenuBackdrop extends PositionComponent {
  _MenuBackdrop()
    : super(
        size: Vector2(PixelViewport.cameraWidth, PixelViewport.cameraHeight),
        priority: 1,
      );

  final _title = TextPaint(style: retroText(15, color: retroGold, bold: true));
  final _subtitle = TextPaint(style: retroText(6, color: retroMuted));
  final _footer = TextPaint(style: retroText(6, color: retroPale));

  @override
  void render(ui.Canvas canvas) {
    canvas.drawRect(
      const ui.Rect.fromLTWH(0, 0, 320, 200),
      ui.Paint()..color = const ui.Color(0xB9000000),
    );
    canvas.drawRect(
      const ui.Rect.fromLTWH(5, 5, 310, 190),
      ui.Paint()..color = const ui.Color(0xDC292D27),
    );
    canvas.drawRect(
      const ui.Rect.fromLTWH(5, 5, 310, 190),
      ui.Paint()
        ..color = const ui.Color(0xFF9A947A)
        ..style = ui.PaintingStyle.stroke
        ..strokeWidth = 2
        ..isAntiAlias = false,
    );
    _center(canvas, _title, 'GRAVEFRONT ARENA', 14);
    _center(canvas, _subtitle, 'REAL-TIME FANTASY SKIRMISH', 39);
    canvas.drawRect(
      const ui.Rect.fromLTWH(16, 53, 288, 2),
      ui.Paint()..color = const ui.Color(0xFF8D8064),
    );
    _center(canvas, _footer, 'RAISE AN ARMY  •  BREAK THE ENEMY KEEP', 181);
  }

  void _center(ui.Canvas canvas, TextPaint paint, String label, double y) {
    final width = paint.toTextPainter(label).width;
    paint.render(canvas, label, Vector2((320 - width) / 2, y));
  }
}

class _FactionCard extends PositionComponent with TapCallbacks {
  _FactionCard(
    this.faction,
    this.assets,
    this.onStart, {
    required super.position,
    required this.accent,
    required this.subtitle,
  }) : super(size: Vector2(143, 110), priority: 2);

  final Faction faction;
  final LevelCacheService assets;
  final void Function(Faction) onStart;
  final ui.Color accent;
  final String subtitle;
  final _name = TextPaint(style: retroText(10, bold: true));
  final _detail = TextPaint(style: retroText(5, color: retroMuted));
  final _button = TextPaint(style: retroText(6, bold: true));
  bool _pressed = false;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    await add(
      assets.unitFrameComponent(faction, UnitRole.melee)
        ..position = Vector2(52, 8)
        ..size = Vector2(39, 46),
    );
  }

  @override
  void onTapDown(TapDownEvent event) => _pressed = true;

  @override
  void onTapUp(TapUpEvent event) {
    _pressed = false;
    onStart(faction);
  }

  @override
  void onTapCancel(TapCancelEvent event) => _pressed = false;

  @override
  void render(ui.Canvas canvas) {
    canvas.drawRect(
      ui.Rect.fromLTWH(0, 0, size.x, size.y),
      ui.Paint()..color = const ui.Color(0xFF33352C),
    );
    canvas.drawRect(
      ui.Rect.fromLTWH(0, 0, size.x, size.y),
      ui.Paint()
        ..color = accent
        ..style = ui.PaintingStyle.stroke
        ..strokeWidth = 2
        ..isAntiAlias = false,
    );
    _center(canvas, _name, faction.label.toUpperCase(), 57);
    _center(canvas, _detail, subtitle, 73);
    _drawButton(canvas);
  }

  void _drawButton(ui.Canvas canvas) {
    final frame = assets.buttonFrame;
    final paint = ui.Paint()..filterQuality = ui.FilterQuality.none;
    const left = 7.0;
    const top = 88.0;
    const width = 129.0;
    const height = 17.0;
    const cap = 5.0;
    canvas.drawImageRect(
      frame,
      const ui.Rect.fromLTWH(0, 0, 6, 22),
      const ui.Rect.fromLTWH(left, top, cap, height),
      paint,
    );
    canvas.drawImageRect(
      frame,
      const ui.Rect.fromLTWH(6, 0, 1, 22),
      const ui.Rect.fromLTWH(left + cap, top, width - cap * 2, height),
      paint,
    );
    canvas.drawImageRect(
      frame,
      const ui.Rect.fromLTWH(94, 0, 6, 22),
      const ui.Rect.fromLTWH(left + width - cap, top, cap, height),
      paint,
    );
    _center(canvas, _button, 'COMMAND THIS FACTION', 92);
    if (_pressed) {
      canvas.drawRect(
        const ui.Rect.fromLTWH(left, top, width, height),
        ui.Paint()..color = const ui.Color(0x66000000),
      );
    }
  }

  void _center(ui.Canvas canvas, TextPaint paint, String label, double y) {
    final width = paint.toTextPainter(label).width;
    paint.render(canvas, label, Vector2((size.x - width) / 2, y));
  }
}
