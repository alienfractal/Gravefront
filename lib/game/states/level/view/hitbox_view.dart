import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

import '../../../camera/pixel_viewport.dart';
import '../services/battle_logic_service.dart';
import 'unit_view.dart';

/// Debug outlines for the rules' target areas and the actual sprite extents.
class HitboxView extends Component {
  HitboxView({
    required this.battle,
    required this.viewport,
    required this.keepSpriteBounds,
    required this.unitViews,
    required this.visible,
  }) : super(priority: 900);

  final BattleState battle;
  final PixelViewport viewport;
  final Rect Function(Faction) keepSpriteBounds;
  final Iterable<UnitView> Function() unitViews;
  final bool Function() visible;

  final Paint _art = Paint()
    ..color = const Color(0xFFFFDC65)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1
    ..isAntiAlias = false;
  final Paint _combat = Paint()
    ..color = const Color(0xFF65EDFF)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1
    ..isAntiAlias = false;
  final Paint _order = Paint()
    ..color = const Color(0xFFFF6B6B)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1
    ..isAntiAlias = false;
  final Paint _selection = Paint()
    ..color = const Color(0xFFFF90DA)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1
    ..isAntiAlias = false;

  Rect keepHurtBounds(Faction faction) =>
      _viewBounds(battle.keepHurtbox(faction));

  Rect keepOrderBounds(Faction faction) =>
      _viewBounds(battle.keepOrderBox(faction));

  Rect _viewBounds(Rectangle<double> box) {
    final topLeft = viewport.viewPoint(Point(box.left, box.top));
    final bottomRight = viewport.viewPoint(Point(box.right, box.bottom));
    return Rect.fromLTRB(
      topLeft.dx,
      topLeft.dy,
      bottomRight.dx,
      bottomRight.dy,
    );
  }

  Rect unitSelectionBounds(BattleUnit unit) {
    return _viewBounds(battle.unitSelectionBox(unit));
  }

  @override
  void render(Canvas canvas) {
    if (!visible()) return;
    for (final faction in Faction.values) {
      canvas.drawRect(keepSpriteBounds(faction).deflate(0.5), _art);
      canvas.drawRect(keepHurtBounds(faction).deflate(0.5), _combat);
      if (faction == battle.enemyFaction) {
        canvas.drawRect(keepOrderBounds(faction).deflate(0.5), _order);
      }
      _drawAnchor(canvas, viewport.viewPoint(battle.basePosition(faction)));
    }
    for (final view in unitViews()) {
      if (!view.isLoaded) continue;
      canvas.drawRect(view.spriteBounds.deflate(0.5), _art);
      if (view.unit.isAlive) {
        canvas.drawRect(
          unitSelectionBounds(view.unit).deflate(0.5),
          _selection,
        );
      }
      _drawAnchor(canvas, viewport.viewPoint(view.unit.position));
    }
    super.render(canvas);
  }

  void _drawAnchor(Canvas canvas, Offset center) {
    canvas.drawLine(center.translate(-2, 0), center.translate(2, 0), _combat);
    canvas.drawLine(center.translate(0, -2), center.translate(0, 2), _combat);
  }
}
