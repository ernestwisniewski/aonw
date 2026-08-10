part of 'turn_reducer.dart';

List<_PendingTurnAction> _pendingTurnActions(
  _ClientState state,
  String playerId,
  MapTileLookup mapTiles,
  TechnologyRuleset technologyRuleset,
) {
  final actions = <_PendingTurnAction>[];
  final unitCandidates = <_PendingUnitCandidate>[];
  for (var index = 0; index < state.units.length; index++) {
    final unit = state.units[index];
    if (!_needsManualUnitAction(unit, playerId)) continue;
    unitCandidates.add(
      _PendingUnitCandidate(
        unit: unit,
        originalIndex: index,
        category: _unitActionCategory(unit),
        seesEnemy: UnitFortificationRules.hasVisibleEnemy(
          unit: unit,
          mapData: mapTiles,
          units: state.units,
        ),
      ),
    );
  }
  unitCandidates.sort();
  actions.addAll(
    unitCandidates.map((candidate) => _PendingUnitAction(candidate.unit)),
  );

  for (final city in state.cities) {
    if (city.ownerPlayerId != playerId) continue;
    if (city.productionQueue != null) continue;
    actions.add(_PendingCityProductionAction(city));
  }

  if (_needsResearchSelection(state, playerId, technologyRuleset)) {
    actions.add(const _PendingResearchAction());
  }

  return actions;
}

bool _needsResearchSelection(
  _ClientState state,
  String playerId,
  TechnologyRuleset ruleset,
) {
  final playerResearch = state.research.forPlayer(playerId);
  if (playerResearch.activeTechnologyId != null) return false;

  for (final technologyId in ruleset.technologies.keys) {
    final availability = TechnologyAvailabilityService.availabilityFor(
      technologyId: technologyId,
      playerResearch: playerResearch,
      ruleset: ruleset,
    );
    if (availability == TechnologyAvailability.available) return true;
  }
  return false;
}

sealed class _PendingTurnAction {
  const _PendingTurnAction();
}

final class _PendingUnitAction extends _PendingTurnAction {
  const _PendingUnitAction(this.unit);

  final GameUnit unit;
}

final class _PendingCityProductionAction extends _PendingTurnAction {
  const _PendingCityProductionAction(this.city);

  final GameCity city;
}

final class _PendingResearchAction extends _PendingTurnAction {
  const _PendingResearchAction();
}

enum _UnitActionCategory {
  combat(0),
  worker(1),
  other(2);

  const _UnitActionCategory(this.order);

  final int order;
}

class _PendingUnitCandidate implements Comparable<_PendingUnitCandidate> {
  const _PendingUnitCandidate({
    required this.unit,
    required this.originalIndex,
    required this.category,
    required this.seesEnemy,
  });

  final GameUnit unit;
  final int originalIndex;
  final _UnitActionCategory category;
  final bool seesEnemy;

  @override
  int compareTo(_PendingUnitCandidate other) {
    final categoryOrder = category.order.compareTo(other.category.order);
    if (categoryOrder != 0) return categoryOrder;
    final enemySightOrder = (seesEnemy ? 0 : 1).compareTo(
      other.seesEnemy ? 0 : 1,
    );
    if (enemySightOrder != 0) return enemySightOrder;
    return originalIndex.compareTo(other.originalIndex);
  }
}
