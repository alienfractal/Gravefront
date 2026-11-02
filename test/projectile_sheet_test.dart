import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gravefront_arena/game/states/level/services/level_cache_service.dart';
import 'package:gravefront_arena/game/states/level/services/sprite_sheet_name.dart';
import 'package:gravefront_arena/gen/assets.gen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('fireball sheets use three native frames in 32-pixel cells', () async {
    for (final asset in [
      Assets.images.terrain.fireball132x323,
      Assets.images.terrain.fireball232x323,
    ]) {
      final data = await rootBundle.load(asset.path);
      final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
      final image = (await codec.getNextFrame()).image;
      final sheet = ProjectileSheet.fromFilename(asset.path, image);

      expect(sheet.frames, 3);
      expect(sheet.sourceWidth, 26);
      expect(sheet.sourceRect(2), const Rect.fromLTWH(52, 0, 26, 26));
      expect(
        sheet.destinationRect(const Offset(20, 20)),
        const Rect.fromLTWH(14, 14, 13, 13),
      );
      expect(
        [sheet.frameAt(0), sheet.frameAt(0.34), sheet.frameAt(0.9)],
        [0, 1, 2],
      );

      image.dispose();
      codec.dispose();
    }
  });

  test('sheet suffix accepts underscore and hyphen before dimensions', () {
    final underscore = SpriteSheetName.parse('effect_32x32-3.png');
    final hyphen = SpriteSheetName.parse('effect-32x32-3.png');
    expect(
      [underscore.width, underscore.height, underscore.frames],
      [32, 32, 3],
    );
    expect([hyphen.width, hyphen.height, hyphen.frames], [32, 32, 3]);
    expect(SpriteSheetName.tryParse('keep.png'), isNull);
    expect(
      () => SpriteSheetName.parse('effect_0x32-3.png'),
      throwsFormatException,
    );
  });
}
