import 'dart:async';
import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import 'game/states/level/services/battle_logic_service.dart';
import 'audio/game_audio_service.dart';
import 'game/states/level/services/level_cache_service.dart';
import 'game/states/level/handlers/level_input_handler.dart';
import 'game/states/level/view/level_play_view.dart';
import 'game/states/level/view/level_screen_view.dart';
import 'game/camera/pixel_viewport.dart';
import 'gamefsm/campaign_fsm.dart';

class RtsGame extends FlameGame with HasKeyboardHandlerComponents {
  RtsGame(
    Faction faction, {
    int level = 1,
    required LevelCacheService assets,
    required this.flow,
    required this.onMenu,
    required this.onAdvance,
    required this.onRetry,
  }) : battle = BattleState(faction, level: level),
       _assets = assets,
       _audio = GameAudioService(level: level),
       super(
         camera: CameraComponent.withFixedResolution(
           width: PixelViewport.cameraWidth,
           height: PixelViewport.cameraHeight,
         ),
       ) {
    camera.viewfinder.anchor = Anchor.topLeft;
  }

  final BattleState battle;
  final CampaignFsm flow;
  final VoidCallback onMenu;
  final VoidCallback onAdvance;
  final VoidCallback onRetry;
  final GameAudioService _audio;
  final LevelCacheService _assets;
  final PixelViewport _viewport = PixelViewport();
  late final LevelPlayView _view = LevelPlayView(
    battle,
    _assets,
    _viewport,
    showHitboxes: () => showHitboxes,
  );
  late final LevelInputHandler _input = LevelInputHandler(toggleHitboxes);
  late final LevelScreenView _screen = LevelScreenView(
    battle: battle,
    flow: flow,
    assets: _assets,
    onMenu: onMenu,
    onAdvance: onAdvance,
    onRetry: onRetry,
    onSound: toggleSound,
    onSpawn: spawn,
    onOrderMode: () => moveMode = !moveMode,
    soundEnabled: () => soundEnabled,
    orderMode: () => moveMode,
    showHitboxes: () => showHitboxes,
  );
  double _accumulator = 0;
  bool _finished = false;
  bool _selecting = false;
  bool moveMode = false;
  bool showHitboxes = false;
  Point<double>? _selectionStart;
  Point<double>? _selectionEnd;

  @override
  Color backgroundColor() => const Color(0xFF172118);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    await _audio.load();
    await _assets.load();
    await world.add(_view);
    await camera.viewport.add(_screen);
    await add(_input);
  }

  @override
  void update(double dt) {
    _accumulator += dt.clamp(0.0, 0.25);
    while (_accumulator >= 1 / 60) {
      battle.step(1 / 60);
      _accumulator -= 1 / 60;
    }
    for (final event in battle.drainSoundEvents().take(6)) {
      _audio.play(event);
    }
    if (!_finished && battle.winner != null) {
      _finished = true;
      flow.finish(battle.winner!);
    }
    super.update(dt);
  }

  bool spawn(UnitRole role) => battle.spawnPlayer(role);

  bool get soundEnabled => _audio.enabled;
  int get level => battle.level;

  void toggleSound() {
    _audio.enabled = !_audio.enabled;
  }

  void toggleHitboxes() => showHitboxes = !showHitboxes;

  @override
  void onRemove() {
    unawaited(_audio.dispose());
    super.onRemove();
  }

  Point<double>? _toWorld(Offset local) {
    if (!hasLayout) return null;
    final point = camera.viewport.globalToLocal(Vector2(local.dx, local.dy));
    return _viewport.toWorld(Offset(point.x, point.y));
  }

  void pointerDown(Offset local, {bool secondary = false}) {
    if (battle.winner != null) return;
    if (_toWorld(local) == null) return;
    if (secondary || moveMode) {
      command(local);
      moveMode = false;
      return;
    }
    _selecting = true;
    beginSelection(local);
  }

  void pointerMove(Offset local) {
    if (_selecting) updateSelection(local);
  }

  void pointerUp(Offset local) {
    if (_selecting) endSelection(local);
    _selecting = false;
  }

  void beginSelection(Offset local) {
    _selectionStart = _toWorld(local);
    _selectionEnd = _selectionStart;
  }

  void updateSelection(Offset local) {
    if (_selectionStart == null) return;
    _selectionEnd = _toWorld(local) ?? _selectionEnd;
  }

  void endSelection(Offset local, {bool add = false}) {
    final start = _selectionStart;
    final end = _toWorld(local) ?? _selectionEnd;
    _selectionStart = null;
    _selectionEnd = null;
    if (start == null || end == null) return;
    if (start.distanceTo(end) < 8) {
      battle.selectPoint(end, add: add);
    } else {
      battle.selectBox(start, end, add: add);
    }
  }

  void command(Offset local) {
    final point = _toWorld(local);
    if (point == null) return;
    battle.issueCommand(point);
  }

  @override
  void render(Canvas canvas) {
    if (hasLayout) {
      _view.selectionStart = _selectionStart;
      _view.selectionEnd = _selectionEnd;
      _view.layout();
    }
    super.render(canvas);
  }
}
