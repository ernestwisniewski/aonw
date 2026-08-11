part of 'game_rendering_coordinator_test.dart';

class _NoopThreatOverlayLayer extends ThreatOverlayLayer {
  @override
  void sync({
    required Component parent,
    required GameClientState state,
    required WorldMap mapData,
    CombatRuleset combatRuleset = CombatRuleset.standard,
    TechnologyRuleset technologyRuleset = TechnologyRulesets.standard,
    bool dimmed = false,
  }) {}
}
