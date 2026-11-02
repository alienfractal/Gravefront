import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:gravefront_arena/game/camera/pixel_viewport.dart';

void main() {
  test(
    '320×200 camera contains the arena and maps its input to battle space',
    () {
      final viewport = PixelViewport();

      expect(PixelViewport.cameraWidth, 320);
      expect(PixelViewport.cameraHeight, 200);
      expect(
        PixelViewport.headerHeight +
            PixelViewport.height +
            PixelViewport.footerHeight,
        PixelViewport.cameraHeight,
      );
      expect(viewport.viewPoint(const Point(500, 310)), const Offset(160, 80));
      expect(viewport.toWorld(const Offset(160, 96)), const Point(500, 310));
      expect(viewport.toWorld(const Offset(160, 8)), isNull);
      expect(viewport.toWorld(const Offset(160, 190)), isNull);
    },
  );
}
