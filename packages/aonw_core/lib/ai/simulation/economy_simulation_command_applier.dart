part of 'economy_simulation.dart';

final class _EconomySimulationCommandApplier {
  _EconomySimulationCommandApplier(this.mapView, this.engineSnapshot);

  final MapReadView mapView;
  CanonicalGameSnapshot engineSnapshot;
  MapTileLookup get mapTiles => mapView;

  _ApplyCommandResult apply({
    required int turn,
    required int tick,
    required PersistentGameState state,
    required DomainCommand command,
    required String actorPlayerId,
    required GameRuleset ruleset,
  }) {
    if (GameEngine.commandFamily(command) != null) {
      return _applyEngineCommand(
        tick: tick,
        state: state,
        command: command,
        actorPlayerId: actorPlayerId,
        ruleset: ruleset,
      );
    }
    return _ApplyCommandResult(
      accepted: false,
      state: state,
      reason: 'unsupported_command_for_simulation',
    );
  }

  _ApplyCommandResult _applyEngineCommand({
    required int tick,
    required PersistentGameState state,
    required DomainCommand command,
    required String actorPlayerId,
    required GameRuleset ruleset,
  }) {
    final result = const SimulationGameEngineAdapter().apply(
      snapshot: engineSnapshot,
      state: state,
      command: command,
      actorPlayerId: actorPlayerId,
      commandTick: tick,
      mapView: mapView,
      ruleset: ruleset,
      movementVisibilityMode: MovementCommandVisibilityMode.unrestrictedPathing,
      combatVisibilityMode: CombatCommandVisibilityMode.unrestricted,
    );
    engineSnapshot = result.snapshot;
    return _ApplyCommandResult(
      accepted: result.accepted,
      state: result.state,
      events: result.events,
      reason: result.reason,
    );
  }

  _ApplyCommandResult finalizeTurn({
    required int tick,
    required PersistentGameState state,
    required Iterable<String> playerIds,
    required GameRuleset ruleset,
  }) {
    final result = const SimulationGameEngineAdapter().finalizeSimultaneousTurn(
      snapshot: engineSnapshot,
      state: state,
      playerIds: playerIds,
      commandTick: tick,
      mapView: mapView,
      ruleset: ruleset,
    );
    if (result.accepted) engineSnapshot = result.snapshot;
    return _ApplyCommandResult(
      accepted: result.accepted,
      state: result.state,
      events: result.events,
      reason: result.reason,
    );
  }
}

_EconomySimulationCommandApplier _economySimulationCommandApplierForSetup({
  required EconomySimulationConfig config,
  required PersistentGameState state,
  required MapReadView mapView,
}) {
  return _EconomySimulationCommandApplier(
    mapView,
    _EconomySimulationSetup.engineSnapshot(
      config: config,
      state: state,
      mapView: mapView,
    ),
  );
}

class _ApplyCommandResult {
  const _ApplyCommandResult({
    required this.accepted,
    required this.state,
    this.events = const [],
    this.reason,
  });
  final bool accepted;
  final PersistentGameState state;
  final List<GameEvent> events;
  final String? reason;
}
