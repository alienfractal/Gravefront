import 'package:flutter_test/flutter_test.dart';
import 'package:gravefront_arena/game/model/campaign_model.dart';
import 'package:gravefront_arena/game/states/level/model/unit_model.dart';
import 'package:gravefront_arena/gamefsm/campaign_fsm.dart';

void main() {
  test('every level uses the same battlefield background', () {
    expect(campaignLevels, hasLength(5));
    expect(
      campaignLevels.map((level) => level.map),
      everyElement(BattlefieldArt.battlefield),
    );
  });

  test('campaign advances, retries, and resets through explicit states', () {
    final model = CampaignModel();
    final flow = CampaignFsm(model);

    flow.start(Faction.hexen);
    expect(flow.phase, CampaignPhase.playing);
    expect(model.level, 1);
    flow.finish(Faction.hexen);
    expect(flow.phase, CampaignPhase.victory);
    flow.advance();
    expect(model.level, 2);

    flow.finish(Faction.heretic);
    expect(flow.phase, CampaignPhase.defeat);
    expect(flow.advance(), isFalse);
    expect(model.level, 2);
    expect(flow.phase, CampaignPhase.defeat);
    expect(flow.retry(), isTrue);
    expect(model.level, 2);
    expect(flow.phase, CampaignPhase.playing);
    expect(flow.retry(), isFalse);

    for (var level = 2; level <= 5; level++) {
      flow.finish(Faction.hexen);
      if (level < 5) flow.advance();
    }
    expect(model.level, 5);
    expect(flow.phase, CampaignPhase.complete);
    flow.returnToMenu();
    expect(flow.phase, CampaignPhase.menu);
    expect(model.faction, isNull);
    expect(model.level, 1);
  });
}
