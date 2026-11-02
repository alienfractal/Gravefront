import 'package:flutter_test/flutter_test.dart';
import 'package:gravefront_arena/audio/game_audio_service.dart';
import 'package:gravefront_arena/gen/assets.gen.dart';

void main() {
  test('all campaign sound cues resolve to generated assets', () {
    final paths = GameAudioService(level: 5).files.toSet();
    expect(paths, hasLength(31));
    expect(paths.difference(Assets.audio.values.toSet()), isEmpty);
  });
}
