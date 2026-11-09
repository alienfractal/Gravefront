import 'dart:async';

import 'package:flame_audio/bgm.dart';
import 'package:flame_audio/flame_audio.dart';

import '../gen/assets.gen.dart';

/// The authored MIDI remains in assets; this OPL3 render plays on every target.
final battleMusicAsset = Assets.audio.onlyRetro2Ogg;

abstract class BattleMusicOutput {
  Future<void> initialize();
  Future<void> play(String asset, {required double volume});
  Future<void> pause();
  Future<void> resume();
  Future<void> stop();
  Future<void> dispose();
}

class FlameBattleMusicOutput implements BattleMusicOutput {
  FlameBattleMusicOutput() : _bgm = Bgm(audioCache: AudioCache(prefix: ''));

  final Bgm _bgm;

  @override
  Future<void> initialize() => _bgm.initialize();

  @override
  Future<void> play(String asset, {required double volume}) =>
      _bgm.play(asset, volume: volume);

  @override
  Future<void> pause() => _bgm.pause();

  @override
  Future<void> resume() => _bgm.resume();

  @override
  Future<void> stop() => _bgm.stop();

  @override
  Future<void> dispose() => _bgm.dispose();
}

/// Owns one battle's looping music and serializes rapid mute/finish commands.
class BattleMusicService {
  BattleMusicService({BattleMusicOutput? output}) : _output = output;

  BattleMusicOutput? _output;
  Future<void> _tail = Future<void>.value();
  bool _ready = false;
  bool _started = false;
  bool _enabled = true;
  bool _finished = false;
  bool _disposed = false;

  Future<void> get settled => _tail;

  Future<void> start() => _queue(() async {
    if (_disposed || _finished || _ready) return;
    final output = _output ??= FlameBattleMusicOutput();
    await output.initialize();
    if (_disposed || _finished) return;
    _ready = true;
    await _sync();
  });

  void setEnabled(bool value) {
    if (_disposed || _enabled == value) return;
    _enabled = value;
    unawaited(_queue(_sync).catchError((Object _) {}));
  }

  void finish() {
    if (_disposed || _finished) return;
    _finished = true;
    unawaited(_queue(_sync).catchError((Object _) {}));
  }

  Future<void> _sync() async {
    if (!_ready || _disposed) return;
    final output = _output!;
    if (_finished) {
      if (_started) {
        await output.stop();
        _started = false;
      }
    } else if (_enabled) {
      if (_started) {
        await output.resume();
      } else {
        await output.play(battleMusicAsset, volume: 0.45);
        _started = true;
      }
    } else if (_started) {
      await output.pause();
    }
  }

  Future<void> _queue(Future<void> Function() operation) {
    final result = _tail.then((_) => operation());
    _tail = result.catchError((Object _) {});
    return result;
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    await _tail;
    await _output?.dispose();
  }
}
