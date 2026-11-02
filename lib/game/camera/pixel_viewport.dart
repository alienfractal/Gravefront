import 'dart:math';
import 'dart:ui';

import '../states/level/services/battle_logic_service.dart';

/// Converts camera-space arena points to the battle simulation and back.
class PixelViewport {
  static const double width = 320;
  static const double height = 160;
  static const double cameraWidth = 320;
  static const double cameraHeight = 200;
  static const double headerHeight = 16;
  static const double footerHeight = 24;

  Point<double>? toWorld(Offset cameraPoint) {
    final x = cameraPoint.dx;
    final y = cameraPoint.dy - headerHeight;
    if (x < 0 || x > width || y < 0 || y > height) return null;
    return Point(
      x / width * BattleState.width,
      y / height * BattleState.height,
    );
  }

  Offset viewPoint(Point<double> point) => Offset(
    (point.x / BattleState.width * width).roundToDouble(),
    (point.y / BattleState.height * height).roundToDouble(),
  );
}
