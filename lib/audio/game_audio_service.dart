import 'dart:async';

import 'package:flame_audio/flame_audio.dart';

import 'battle_music_service.dart';
import '../game/states/level/services/battle_logic_service.dart';
import '../gen/assets.gen.dart';

final _audioAssets = {
  for (final path in Assets.audio.values)
    if (path.endsWith('.wav'))
      path.substring(path.lastIndexOf('/') + 1, path.length - 4): path,
};

String soundAssetPathFor(BattleSoundEvent event) {
  if (event.sound == BattleSound.summon) return Assets.audio.summonWav;
  final unit = assetNameFor(event.faction, event.role);
  final name = '${unit}_${event.sound.name}';
  final path = _audioAssets[name];
  if (path == null) throw StateError('Missing generated audio asset $name');
  return path;
}

class GameAudioService {
  GameAudioService({required this.level, BattleMusicService? music})
    : _music = music ?? BattleMusicService();

  final int level;
  final BattleMusicService _music;
  final AudioCache _cache = AudioCache(prefix: '');
  final Map<String, AudioPool> _pools = {};
  bool _enabled = true;
  bool _disposed = false;
  Future<void>? _loading;

  bool get enabled => _enabled;

  set enabled(bool value) {
    if (_disposed) return;
    _enabled = value;
    _music.setEnabled(value);
  }

  void finishBattle() => _music.finish();

  Iterable<String> get files sync* {
    yield Assets.audio.summonWav;
    for (final role in UnitRole.values) {
      if (role.unlockLevel > level) continue;
      for (final faction in Faction.values) {
        for (final sound in [
          BattleSound.attack,
          BattleSound.hurt,
          BattleSound.death,
        ]) {
          yield soundAssetPathFor(BattleSoundEvent(sound, faction, role));
        }
      }
    }
  }

  Future<void> load() => _loading ??= _load();

  Future<void> _load() async {
    for (final file in files) {
      if (_disposed) return;
      try {
        await _cache.load(file);
        final pool = await AudioPool.createFromAsset(
          path: file,
          audioCache: _cache,
          minPlayers:
              file == Assets.audio.summonWav || file.endsWith('_attack.wav')
              ? 1
              : 0,
          maxPlayers: 3,
        );
        if (_disposed) {
          await pool.dispose();
          return;
        }
        _pools[file] = pool;
      } catch (_) {
        // An unavailable device or codec must not stop the battle.
      }
    }
    if (_disposed) return;
    try {
      await _music.start();
    } catch (_) {
      // Music failure must not prevent battle input or sound effects.
    }
  }

  void play(BattleSoundEvent event) {
    if (!_enabled || _disposed) return;
    final pool = _pools[soundAssetPathFor(event)];
    if (pool != null) unawaited(_play(pool));
  }

  Future<void> _play(AudioPool pool) async {
    try {
      await pool.start(volume: 0.65);
    } catch (_) {
      // Ignore playback failure without changing simulation state.
    }
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _music.finish();
    await _loading;
    await _music.dispose();
    for (final pool in _pools.values) {
      await pool.dispose();
    }
    _pools.clear();
    await _cache.clearAll();
  }
}
