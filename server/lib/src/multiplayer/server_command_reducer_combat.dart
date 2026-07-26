part of 'server_command_reducer.dart';

extension _ServerCommandReducerCombat on ServerCommandReducer {
  _CommandApplication _applyCombatCommand({
    required GameSave save,
    required PersistentGameState state,
    required AttackHexCommand command,
    required String actorPlayerId,
    required int commandTick,
    required MapTileLookup mapTiles,
    required GameRuleset ruleset,
  }) {
    final result = const CombatCommandResolver().resolve(
      state: CombatCommandState(
        units: state.units,
        cities: state.cities,
        artifacts: state.artifacts,
        fogOfWar: state.fogOfWar,
        research: state.research,
        intendedAttacks: state.runtimeState.intendedAttacks,
        diplomacy: state.runtimeState.diplomacy,
        resourceTradeAgreements: state.runtimeState.resourceTradeAgreements,
        playerIds: state.knownPlayerIds,
      ),
      command: command,
      actorPlayerId: actorPlayerId,
      turn: save.turn,
      commandTick: commandTick,
      mapTiles: mapTiles,
      ruleset: ruleset,
    );
    return _applicationFromCombatResult(
      save: save,
      state: state,
      result: result,
    );
  }

  _CommandApplication _applicationFromCombatResult({
    required GameSave save,
    required PersistentGameState state,
    required CombatCommandResult result,
  }) {
    if (!result.accepted) {
      return _applicationFrom(
        save: save,
        accepted: false,
        state: state,
        reason: result.reason,
      );
    }
    return _applicationFrom(
      save: save,
      accepted: true,
      state: _projectCombatResult(state, result),
      events: result.events,
    );
  }
}

PersistentGameState _projectCombatResult(
  PersistentGameState state,
  CombatCommandResult result,
) {
  final units = _changedValue(state.units, result.units);
  final cities = _changedValue(state.cities, result.cities);
  final artifacts = _changedValue(state.artifacts, result.artifacts);
  final fogOfWar = _changedValue(state.fogOfWar, result.fogOfWar);
  final runtimeState = _projectCombatRuntimeState(state.runtimeState, result);
  if (!_hasCombatStateChanges(
    units: units,
    cities: cities,
    artifacts: artifacts,
    fogOfWar: fogOfWar,
    runtimeState: runtimeState,
  )) {
    return state;
  }
  return state.copyWith(
    units: units,
    cities: cities,
    artifacts: artifacts,
    fogOfWar: fogOfWar,
    runtimeState: runtimeState,
  );
}

GameRuntimeState? _projectCombatRuntimeState(
  GameRuntimeState current,
  CombatCommandResult result,
) {
  final intendedAttacks = _changedValue(
    current.intendedAttacks,
    result.intendedAttacks,
  );
  final diplomacy = _changedValue(current.diplomacy, result.diplomacy);
  final resourceTradeAgreements = _changedValue(
    current.resourceTradeAgreements,
    result.resourceTradeAgreements,
  );
  if (!_hasCombatRuntimeChanges(
    intendedAttacks,
    diplomacy,
    resourceTradeAgreements,
  )) {
    return null;
  }
  return current.copyWith(
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
  required GameRuntimeState? runtimeState,
}) =>
    units != null ||
    cities != null ||
    artifacts != null ||
    fogOfWar != null ||
    runtimeState != null;

bool _hasCombatRuntimeChanges(
  List<IntendedAttack>? intendedAttacks,
  DiplomacyState? diplomacy,
  List<ResourceTradeAgreement>? resourceTradeAgreements,
) =>
    intendedAttacks != null ||
    diplomacy != null ||
    resourceTradeAgreements != null;

T? _changedValue<T>(T current, T next) =>
    identical(current, next) ? null : next;
