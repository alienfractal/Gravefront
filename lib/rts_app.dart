import 'dart:async';

import 'package:flame/game.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

import 'game/model/campaign_model.dart';
import 'game/states/level/model/unit_model.dart';
import 'game/states/level/services/level_cache_service.dart';
import 'gravefront_arena_game.dart';
import 'game/states/main_menu/view/main_menu_view.dart';
import 'gamefsm/campaign_fsm.dart';

class GravefrontArenaApp extends StatelessWidget {
  const GravefrontArenaApp({super.key});

  @override
  Widget build(BuildContext context) => const RtsHome();
}

class RtsHome extends StatefulWidget {
  const RtsHome({super.key});

  @override
  State<RtsHome> createState() => _RtsHomeState();
}

class _RtsHomeState extends State<RtsHome> {
  final CampaignModel _campaign = CampaignModel();
  late final CampaignFsm _flow = CampaignFsm(_campaign);
  final LevelCacheService _levelSprites = LevelCacheService();
  late MainMenuGame _menuGame;
  RtsGame? _game;

  @override
  void initState() {
    super.initState();
    _menuGame = MainMenuGame(cache: _levelSprites, onStart: _start);
    unawaited(_preloadLevelSprites());
  }

  Future<void> _preloadLevelSprites() async {
    try {
      await _levelSprites.load();
    } catch (_) {
      // RtsGame awaits the same load and surfaces a missing battle asset.
    }
  }

  @override
  void dispose() {
    _game?.pauseEngine();
    _game?.stopAudio();
    _menuGame.pauseEngine();
    unawaited(_levelSprites.dispose());
    super.dispose();
  }

  void _start(Faction faction) {
    _flow.start(faction);
    _openLevel();
  }

  void _openLevel() {
    _game?.pauseEngine();
    _game?.stopAudio();
    setState(() {
      _game = RtsGame(
        _campaign.faction!,
        level: _campaign.level,
        assets: _levelSprites,
        flow: _flow,
        onMenu: _backToMenu,
        onAdvance: _advance,
        onRetry: _retry,
      );
    });
  }

  void _advance() {
    if (_flow.advance()) _openLevel();
  }

  void _retry() {
    if (_flow.retry()) _openLevel();
  }

  void _backToMenu() {
    _game?.pauseEngine();
    _game?.stopAudio();
    _flow.returnToMenu();
    setState(() {
      _game = null;
      _menuGame = MainMenuGame(cache: _levelSprites, onStart: _start);
    });
  }

  @override
  Widget build(BuildContext context) {
    final game = _game;
    if (game == null) {
      return GameWidget(key: ValueKey(_menuGame), game: _menuGame);
    }
    return Listener(
      key: ValueKey(game),
      behavior: HitTestBehavior.opaque,
      onPointerDown: (event) => game.pointerDown(
        event.localPosition,
        secondary: (event.buttons & kSecondaryMouseButton) != 0,
      ),
      onPointerMove: (event) => game.pointerMove(event.localPosition),
      onPointerUp: (event) => game.pointerUp(event.localPosition),
      onPointerCancel: (event) => game.pointerUp(event.localPosition),
      child: GameWidget(game: game),
    );
  }
}
