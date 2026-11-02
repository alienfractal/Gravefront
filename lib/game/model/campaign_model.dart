import '../states/level/model/unit_model.dart';

enum BattlefieldArt { battlefield }

class CampaignLevel {
  const CampaignLevel(this.number, this.name, this.map, this.enemySpawnSeconds);

  final int number;
  final String name;
  final BattlefieldArt map;
  final double enemySpawnSeconds;
}

const campaignLevels = [
  CampaignLevel(1, 'The First March', BattlefieldArt.battlefield, 4.0),
  CampaignLevel(2, 'Sunken Road', BattlefieldArt.battlefield, 3.7),
  CampaignLevel(3, 'Broken Shrine', BattlefieldArt.battlefield, 3.4),
  CampaignLevel(4, 'Blood Grove', BattlefieldArt.battlefield, 3.1),
  CampaignLevel(5, 'Final Siege', BattlefieldArt.battlefield, 2.8),
];

/// Progress persists while each level receives a fresh battle simulation.
class CampaignModel {
  Faction? faction;
  int level = 1;
}
