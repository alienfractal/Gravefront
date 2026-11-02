import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';

import '../../../../gamefsm/campaign_fsm.dart';
import '../../../camera/pixel_viewport.dart';
import '../../../view/retro_theme.dart';
import '../services/battle_logic_service.dart';
import '../services/level_cache_service.dart';

/// The pixel-aligned HUD and its interactive Flame components.
class LevelScreenView extends PositionComponent {
  static const double _footerTop =
      PixelViewport.headerHeight + PixelViewport.height;

  LevelScreenView({
    required this.battle,
    required this.flow,
    required this.assets,
    required this.onMenu,
    required this.onAdvance,
    required this.onRetry,
    required this.onSound,
    required this.onSpawn,
    required this.onOrderMode,
    required this.soundEnabled,
    required this.orderMode,
    required this.showHitboxes,
  }) : super(
         size: Vector2(PixelViewport.cameraWidth, PixelViewport.cameraHeight),
         priority: 1000,
       );

  final BattleState battle;
  final CampaignFsm flow;
  final LevelCacheService assets;
  final VoidCallback onMenu;
  final VoidCallback onAdvance;
  final VoidCallback onRetry;
  final VoidCallback onSound;
  final bool Function(UnitRole) onSpawn;
  final VoidCallback onOrderMode;
  final bool Function() soundEnabled;
  final bool Function() orderMode;
  final bool Function() showHitboxes;

  final _gold = TextPaint(style: retroText(7, color: retroGold, bold: true));
  final _light = TextPaint(style: retroText(6, bold: true));
  final _muted = TextPaint(style: retroText(5, color: retroMuted));
  late final HudButton _menu;
  late final HudButton _sound;
  late final HudButton _order;
  late final HudButton _result;
  final Map<UnitRole, HudButton> _spawns = {};

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _menu = HudButton('MENU', onPressed: onMenu, frame: assets.buttonFrame)
      ..position = Vector2(3, 1)
      ..size = Vector2(37, 14);
    _sound = HudButton('SFX', onPressed: onSound, frame: assets.buttonFrame)
      ..position = Vector2(289, 1)
      ..size = Vector2(28, 14);
    _order =
        HudButton(
            'MOVE /\nATTACK',
            onPressed: onOrderMode,
            frame: assets.buttonFrame,
          )
          ..position = Vector2(245, _footerTop + 1)
          ..size = Vector2(72, 22);
    _result =
        HudButton(
            '',
            frame: assets.buttonFrame,
            onPressed: () {
              switch (flow.phase) {
                case CampaignPhase.complete:
                  onMenu();
                case CampaignPhase.victory:
                  onAdvance();
                case CampaignPhase.defeat:
                  onRetry();
                default:
                  break;
              }
            },
          )
          ..position = Vector2(100, PixelViewport.headerHeight + 91)
          ..size = Vector2(120, 22)
          ..priority = 10;
    final children = <Component>[_menu, _sound, _order, _result];
    for (final role in battle.unlockedRoles) {
      final index = battle.unlockedRoles.indexOf(role);
      final button =
          HudButton(
              '',
              frame: assets.buttonFrame,
              onPressed: () {
                onSpawn(role);
              },
            )
            ..position = Vector2(74 + index * 34, _footerTop + 1)
            ..size = Vector2(32, 22);
      final atlas = assets.unitAtlas(battle.playerFaction, role, 'walk');
      button.icon = atlas.image;
      button.iconSource = atlas.sourceRect(0, 1);
      _spawns[role] = button;
      children.add(button);
    }
    await addAll(children);
  }

  @override
  void update(double dt) {
    final finished = battle.winner != null;
    _menu.enabled = !finished;
    _sound.enabled = !finished;
    _order.enabled = !finished && battle.selectedIds.isNotEmpty;
    _order.label = orderMode() ? 'CANCEL\nORDER' : 'MOVE /\nATTACK';
    _sound.label = soundEnabled() ? 'SFX ON' : 'SFX OFF';
    _result.enabled = finished;
    _result.visible = finished;
    _result.label = switch (flow.phase) {
      CampaignPhase.complete => 'BACK TO MENU',
      CampaignPhase.victory => 'NEXT LEVEL',
      CampaignPhase.defeat => 'RETRY LEVEL',
      _ => '',
    };
    for (final entry in _spawns.entries) {
      entry.value.enabled =
          !finished &&
          battle.playerMana >= statsFor(battle.playerFaction, entry.key).cost;
    }
    super.update(dt);
  }

  @override
  void render(ui.Canvas canvas) {
    final fill = ui.Paint()..color = retroStone;
    final rim = ui.Paint()..color = const Color(0xFF9A947A);
    canvas.drawRect(
      const ui.Rect.fromLTWH(
        0,
        0,
        PixelViewport.cameraWidth,
        PixelViewport.headerHeight,
      ),
      fill,
    );
    canvas.drawRect(
      const ui.Rect.fromLTWH(
        0,
        PixelViewport.headerHeight - 2,
        PixelViewport.cameraWidth,
        2,
      ),
      rim,
    );
    canvas.drawRect(
      const ui.Rect.fromLTWH(
        0,
        _footerTop,
        PixelViewport.cameraWidth,
        PixelViewport.footerHeight,
      ),
      fill,
    );
    canvas.drawRect(
      const ui.Rect.fromLTWH(0, _footerTop, PixelViewport.cameraWidth, 2),
      rim,
    );

    _gold.render(
      canvas,
      battle.playerFaction.label.toUpperCase(),
      Vector2(45, 0),
    );
    _muted.render(
      canvas,
      'LEVEL ${battle.level}/5  ${battle.campaignLevel.name.toUpperCase()}',
      Vector2(45, 9),
    );
    _light.render(canvas, 'MANA ${battle.playerMana.floor()}', Vector2(139, 2));
    _light.render(
      canvas,
      'KEEP ${battle.playerBaseHealth.ceil()}',
      Vector2(191, 2),
    );
    _muted.render(
      canvas,
      'FOE ${battle.enemyBaseHealth.ceil()}',
      Vector2(244, 9),
    );

    final selected = battle.units.where(
      (unit) => battle.selectedIds.contains(unit.id),
    );
    final portrait = selected.isEmpty ? null : selected.first;
    _drawPortrait(
      canvas,
      portrait?.faction ?? battle.playerFaction,
      portrait?.role ?? UnitRole.melee,
      const ui.Rect.fromLTWH(4, _footerTop + 3, 18, 18),
    );
    _light.render(
      canvas,
      '${battle.selectedIds.length}',
      Vector2(26, _footerTop + 3),
    );
    _muted.render(canvas, 'SELECTED', Vector2(26, _footerTop + 12));

    for (final entry in _spawns.entries) {
      final role = entry.key;
      final button = entry.value;
      final stats = statsFor(battle.playerFaction, role);
      final name = assetNameFor(battle.playerFaction, role);
      button.label = '${name.substring(0, 3).toUpperCase()}\n${stats.cost}M';
    }
    if (battle.manaPowerUp != null && battle.winner == null) {
      _gold.render(
        canvas,
        'CRYSTAL +60',
        Vector2(146, PixelViewport.headerHeight + 2),
      );
    }
    if (showHitboxes()) {
      canvas.drawRect(
        const ui.Rect.fromLTWH(0, PixelViewport.headerHeight, 320, 9),
        ui.Paint()..color = const Color(0xD0101714),
      );
      _muted.render(
        canvas,
        '1 BOXES  YELLOW ART  CYAN KEEP HURT  RED KEEP CLICK  PINK UNIT PICK',
        Vector2(4, PixelViewport.headerHeight + 1),
      );
    }
    if (battle.winner != null) {
      canvas.drawRect(
        const ui.Rect.fromLTWH(
          0,
          PixelViewport.headerHeight,
          PixelViewport.cameraWidth,
          PixelViewport.height,
        ),
        ui.Paint()..color = const Color(0xC0000000),
      );
      final title = switch (flow.phase) {
        CampaignPhase.complete => 'CAMPAIGN COMPLETE',
        CampaignPhase.victory => 'LEVEL CLEAR',
        _ => 'DEFEAT',
      };
      _gold.render(
        canvas,
        title,
        Vector2(108, PixelViewport.headerHeight + 52),
      );
      _light.render(
        canvas,
        'LEVEL ${battle.level}  ${battle.campaignLevel.name.toUpperCase()}',
        Vector2(91, PixelViewport.headerHeight + 69),
      );
    }
    super.render(canvas);
  }

  void _drawPortrait(
    ui.Canvas canvas,
    Faction faction,
    UnitRole role,
    ui.Rect destination,
  ) {
    final atlas = assets.unitAtlas(faction, role, 'walk');
    canvas.drawImageRect(
      atlas.image,
      atlas.sourceRect(0, 1),
      destination,
      ui.Paint()..filterQuality = ui.FilterQuality.none,
    );
  }
}

/// A Flame hit target with a pixel-sized button surface.
class HudButton extends PositionComponent with TapCallbacks {
  HudButton(this.label, {required this.onPressed, required this.frame})
    : super(priority: 2);

  String label;
  final VoidCallback onPressed;
  final ui.Image frame;
  bool enabled = true;
  bool visible = true;
  bool _pressed = false;
  ui.Image? icon;
  ui.Rect? iconSource;
  final _text = TextPaint(style: retroText(5, bold: true));

  @override
  void onTapDown(TapDownEvent event) {
    if (enabled) _pressed = true;
  }

  @override
  void onTapUp(TapUpEvent event) {
    if (_pressed && enabled) onPressed();
    _pressed = false;
  }

  @override
  void onTapCancel(TapCancelEvent event) => _pressed = false;

  @override
  void render(ui.Canvas canvas) {
    if (!visible) return;
    final paint = ui.Paint()..filterQuality = ui.FilterQuality.none;
    final cap = (size.y * 6 / 22).roundToDouble();
    canvas.drawImageRect(
      frame,
      const ui.Rect.fromLTWH(0, 0, 6, 22),
      ui.Rect.fromLTWH(0, 0, cap, size.y),
      paint,
    );
    canvas.drawImageRect(
      frame,
      const ui.Rect.fromLTWH(6, 0, 1, 22),
      ui.Rect.fromLTWH(cap, 0, size.x - cap * 2, size.y),
      paint,
    );
    canvas.drawImageRect(
      frame,
      const ui.Rect.fromLTWH(94, 0, 6, 22),
      ui.Rect.fromLTWH(size.x - cap, 0, cap, size.y),
      paint,
    );
    if (icon != null && iconSource != null) {
      canvas.drawImageRect(
        icon!,
        iconSource!,
        const ui.Rect.fromLTWH(2, 2, 12, 14),
        ui.Paint()..filterQuality = ui.FilterQuality.none,
      );
    }
    final lines = label.split('\n');
    final startY = icon == null ? (size.y - lines.length * 7) / 2 : 1.0;
    for (var i = 0; i < lines.length; i++) {
      final width = _text.toTextPainter(lines[i]).width;
      _text.render(
        canvas,
        lines[i],
        Vector2(icon == null ? (size.x - width) / 2 : 16, startY + i * 8),
      );
    }
    if (_pressed || !enabled) {
      canvas.drawRect(
        ui.Rect.fromLTWH(0, 0, size.x, size.y),
        ui.Paint()
          ..color = _pressed
              ? const Color(0x55000000)
              : const Color(0x88000000),
      );
    }
    super.render(canvas);
  }
}
