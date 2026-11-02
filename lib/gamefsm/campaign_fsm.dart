import '../game/model/campaign_model.dart';
import '../game/states/level/model/unit_model.dart';

enum CampaignPhase { menu, playing, victory, defeat, complete }

/// Owns menu, level, victory, and retry transitions for one campaign run.
class CampaignFsm {
  CampaignFsm(this.model);

  final CampaignModel model;
  CampaignPhase phase = CampaignPhase.menu;

  void start(Faction faction) {
    model.faction = faction;
    model.level = 1;
    phase = CampaignPhase.playing;
  }

  void finish(Faction winner) {
    if (phase != CampaignPhase.playing || model.faction == null) return;
    phase = winner == model.faction
        ? model.level == campaignLevels.length
              ? CampaignPhase.complete
              : CampaignPhase.victory
        : CampaignPhase.defeat;
  }

  bool advance() {
    if (phase != CampaignPhase.victory) return false;
    model.level++;
    phase = CampaignPhase.playing;
    return true;
  }

  bool retry() {
    if (phase != CampaignPhase.defeat) return false;
    phase = CampaignPhase.playing;
    return true;
  }

  void returnToMenu() {
    model.faction = null;
    model.level = 1;
    phase = CampaignPhase.menu;
  }
}
