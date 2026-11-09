import 'package:flutter_test/flutter_test.dart';
import 'package:gravefront_arena/audio/battle_music_service.dart';
import 'package:gravefront_arena/gen/assets.gen.dart';

class FakeMusicOutput implements BattleMusicOutput {
  final calls = <String>[];
  String? asset;
  double? volume;

  @override
  Future<void> initialize() async => calls.add('initialize');

  @override
  Future<void> play(String asset, {required double volume}) async {
    this.asset = asset;
    this.volume = volume;
    calls.add('play');
  }

  @override
  Future<void> pause() async => calls.add('pause');

  @override
  Future<void> resume() async => calls.add('resume');

  @override
  Future<void> stop() async => calls.add('stop');

  @override
  Future<void> dispose() async => calls.add('dispose');
}

void main() {
  test('battle music follows mute, finish, and disposal', () async {
    final output = FakeMusicOutput();
    final music = BattleMusicService(output: output);

    await music.start();
    expect(output.asset, Assets.audio.onlyRetro2Ogg);
    expect(output.volume, 0.45);
    music.setEnabled(false);
    await music.settled;
    music.setEnabled(true);
    await music.settled;
    music.finish();
    await music.settled;
    music.setEnabled(false);
    await music.dispose();

    expect(output.calls, [
      'initialize',
      'play',
      'pause',
      'resume',
      'stop',
      'dispose',
    ]);
  });

  test('mute before start prevents playback until enabled', () async {
    final output = FakeMusicOutput();
    final music = BattleMusicService(output: output);

    music.setEnabled(false);
    await music.start();
    expect(output.calls, ['initialize']);
    music.setEnabled(true);
    await music.settled;
    expect(output.calls, ['initialize', 'play']);
    await music.dispose();
  });
}
