part of 'server_command_reducer.dart';

extension _ServerCommandReducerCombat on ServerCommandReducer {
  _CommandApplication _applyCombatCommand({
    required CanonicalGameSnapshot snapshot,
    required AttackHexCommand command,
    required String actorPlayerId,
    required int commandTick,
    required MapTileLookup mapTiles,
    required GameRuleset ruleset,
  }) {
    final domain = snapshot.domain;
    final result = const CombatCommandResolver().resolve(
      state: CombatCommandState(
        units: domain.units,
        cities: domain.cities,
        artifacts: domain.artifacts,
        fogOfWar: domain.fogOfWar,
        research: domain.research,
        intendedAttacks: domain.intendedAttacks,
        diplomacy: domain.diplomacy,
        resourceTradeAgreements: domain.resourceTradeAgreements,
        playerIds: domain.participants.map((participant) => participant.id),
      ),
      command: command,
      actorPlayerId: actorPlayerId,
      turn: domain.turn,
      commandTick: commandTick,
      mapTiles: mapTiles,
      ruleset: ruleset,
    );
    return _applicationFromCombatResult(snapshot: snapshot, result: result);
  }

  _CommandApplication _applicationFromCombatResult({
    required CanonicalGameSnapshot snapshot,
    required CombatCommandResult result,
  }) {
    if (!result.accepted) {
      return _applicationFrom(
        snapshot: snapshot,
        accepted: false,
        reason: result.reason,
      );
    }
    final domain = snapshot.domain;
    final nextDomain = _projectCombatResult(domain, result);
    return _applicationFrom(
      snapshot: snapshot,
      accepted: true,
      domain: identical(nextDomain, domain) ? null : nextDomain,
      events: result.events,
    );
  }
}

DomainState _projectCombatResult(
  DomainState domain,
  CombatCommandResult result,
) {
  final units = _changedValue(domain.units, result.units);
  final cities = _changedValue(domain.cities, result.cities);
  final artifacts = _changedValue(domain.artifacts, result.artifacts);
  final fogOfWar = _changedValue(domain.fogOfWar, result.fogOfWar);
  final intendedAttacks = _changedValue(
    domain.intendedAttacks,
    result.intendedAttacks,
  );
  final diplomacy = _changedValue(domain.diplomacy, result.diplomacy);
  final resourceTradeAgreements = _changedValue(
    domain.resourceTradeAgreements,
    result.resourceTradeAgreements,
  );
  if (!_hasCombatStateChanges(
    units: units,
    cities: cities,
    artifacts: artifacts,
    fogOfWar: fogOfWar,
    intendedAttacks: intendedAttacks,
    diplomacy: diplomacy,
    resourceTradeAgreements: resourceTradeAgreements,
  )) {
    return domain;
  }
  return domain.copyWith(
    units: units,
    cities: cities,
    artifacts: artifacts,
    fogOfWar: fogOfWar,
    intendedAttacks: intendedAttacks,
    diplomacy: diplomacy,
    resourceTradeAgreements: resourceTradeAgreements,
  );
}

bool _hasCombatStateChanges({
  required List<GameUnit>? units,
  required List<GameCity>? cities,
  required List<WorldArtifact>? artifacts,
  required FogOfWarState? fogOfWar,
  required List<IntendedAttack>? intendedAttacks,
  required DiplomacyState? diplomacy,
  required List<ResourceTradeAgreement>? resourceTradeAgreements,
}) =>
    units != null ||
    cities != null ||
    artifacts != null ||
    fogOfWar != null ||
    intendedAttacks != null ||
    diplomacy != null ||
    resourceTradeAgreements != null;

T? _changedValue<T>(T current, T next) =>
    identical(current, next) ? null : next;
