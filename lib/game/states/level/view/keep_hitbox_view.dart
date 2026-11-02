import 'package:flame/components.dart';

import '../services/battle_logic_service.dart';

/// The opposing keep target used by unit range collision behaviors.
class KeepHitboxView extends PositionComponent {
  KeepHitboxView(this.faction);

  final Faction faction;
}
