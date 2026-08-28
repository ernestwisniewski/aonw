import 'dart:async';

import '../../turns/application/turn_action_state.dart';
import '../../turns/application/turn_command_runner.dart';
import '../../turns/application/turn_session_port.dart';
import '../../unit_actions/application/action_deck_state.dart';
import '../../unit_actions/application/unit_action_command_runner.dart';
import '../../unit_actions/application/unit_action_session_port.dart';
import '../../unit_actions/read_model/unit_action_view.dart';
import '../read_model/map_view.dart';
import '../read_model/movement_view.dart';
import 'game_session_state.dart';
import 'map_interaction_state.dart';
import 'map_session_port.dart';
import 'movement_command_runner.dart';
import 'movement_session_port.dart';
import 'unit_action_state_reducer.dart';

typedef MapDiagnosticReporter =
    void Function(String code, Object error, StackTrace stackTrace);

final class MapCoordinator {
  MapCoordinator({
    required MapSessionPort session,
    required MovementSessionPort movement,
    required UnitActionSessionPort unitActions,
    required TurnSessionPort turns,
    this.assets = MapAssetPaths.starter,
    MapDiagnosticReporter? diagnosticReporter,
  }) : _session = session,
       _movement = MovementCommandRunner(
         session: movement,
         diagnosticReporter: diagnosticReporter ?? _ignoreDiagnostic,
       ),
       _unitActions = UnitActionCommandRunner(
         session: unitActions,
         diagnosticReporter: diagnosticReporter ?? _ignoreDiagnostic,
       ),
       _turns = TurnCommandRunner(
         session: turns,
         diagnosticReporter: diagnosticReporter ?? _ignoreDiagnostic,
       ),
       _diagnosticReporter = diagnosticReporter ?? _ignoreDiagnostic;

  final MapSessionPort _session;
  final MovementCommandRunner _movement;
  final UnitActionCommandRunner _unitActions;
  final TurnCommandRunner _turns;
  final MapDiagnosticReporter _diagnosticReporter;
  final MapAssetPaths assets;
  final StreamController<GameSessionState> _changes =
      StreamController<GameSessionState>.broadcast(sync: true);
  GameSessionState _state = const GameSessionLoading();
  var _disposed = false;
  var _loadGeneration = 0;
  var _interactionGeneration = 0;
  var _actionCorrelationId = 0;
  var _turnCorrelationId = 0;

  GameSessionState get state => _state;

  Stream<GameSessionState> get changes => _changes.stream;

  Future<void> load() async {
    if (_disposed) return;
    final generation = ++_loadGeneration;
    _interactionGeneration += 1;
    _setState(const GameSessionLoading());
    try {
      final scene = await _session.load(assets);
      if (!_isCurrent(generation)) return;
      _setState(GameSessionReady.initial(scene));
    } on MapLoadException catch (error, stackTrace) {
      if (!_isCurrent(generation)) return;
      final cause = error.diagnosticCause;
      if (cause != null) {
        _diagnosticReporter(
          error.code,
          cause,
          error.diagnosticStackTrace ?? stackTrace,
        );
      }
      _setState(GameSessionFailure(code: _loadFailureCode(error.code)));
    } on Object catch (error, stackTrace) {
      if (!_isCurrent(generation)) return;
      _diagnosticReporter('unexpected_map_failure', error, stackTrace);
      _setState(
        const GameSessionFailure(code: MapLoadFailureViewCode.mapUnavailable),
      );
    }
  }

  void hover(MapHexCoordinate? coordinate) {
    final current = _state;
    if (current is! GameSessionReady) return;
    final next = coordinate != null && current.scene.map.contains(coordinate)
        ? coordinate
        : null;
    if (next == current.interaction.hovered) return;
    _setState(
      current.withInteraction(
        current.interaction.copyWith(hovered: next, clearHovered: next == null),
      ),
    );
  }

  void select(MapHexCoordinate? coordinate) {
    unawaited(_select(coordinate));
  }

  Future<void> _select(MapHexCoordinate? coordinate) async {
    final current = _state;
    if (current is! GameSessionReady || _interactionBusy(current.interaction)) {
      return;
    }
    final next = coordinate != null && current.scene.map.contains(coordinate)
        ? coordinate
        : null;
    final generation = ++_interactionGeneration;
    if (next == null) {
      _clearSelection(current);
      return;
    }

    final unit = current.recipient.controlledUnitAt(next);
    if (unit != null) {
      await _selectControlledUnit(current, next, unit.id, generation);
      return;
    }

    final selectedUnitId = current.interaction.selectedUnitId;
    final reachable = current.interaction.reachable;
    if (selectedUnitId != null && reachable?.tileAt(next) != null) {
      await _previewRoute(current, next, selectedUnitId, generation);
      return;
    }

    _selectPlainHex(current, next);
  }

  void _clearSelection(GameSessionReady current) {
    _setState(
      current.withInteraction(
        current.interaction.copyWith(
          clearSelected: true,
          clearSelectedUnit: true,
          clearReachable: true,
          clearRoute: true,
          clearActionDeck: true,
          movementPending: false,
          clearMovementError: true,
        ),
      ),
    );
  }

  void _selectPlainHex(GameSessionReady current, MapHexCoordinate coordinate) {
    _setState(
      current.withInteraction(
        current.interaction.copyWith(
          selected: coordinate,
          clearSelectedUnit: true,
          clearReachable: true,
          clearRoute: true,
          clearActionDeck: true,
          movementPending: false,
          clearMovementError: true,
        ),
      ),
    );
  }

  Future<void> _selectControlledUnit(
    GameSessionReady current,
    MapHexCoordinate coordinate,
    String unitId,
    int generation,
  ) async {
    _setState(
      current.withInteraction(
        current.interaction.copyWith(
          selected: coordinate,
          selectedUnitId: unitId,
          actionDeck: ActionDeckViewState(unitId: unitId),
          clearReachable: true,
          clearRoute: true,
          movementPending: true,
          clearMovementError: true,
        ),
      ),
    );
    final completion = await _movement.reachable(
      expectedRevision: current.recipient.stamp.revision,
      unitId: unitId,
    );
    final ready = _currentInteraction(generation);
    if (ready == null) return;
    final failure = completion.failure;
    if (failure != null) {
      _setState(_movementFailureState(ready, completion));
    } else {
      _setState(
        ready.withInteraction(
          ready.interaction.copyWith(
            reachable: completion.result!,
            movementPending: false,
          ),
        ),
      );
    }
  }

  Future<void> _previewRoute(
    GameSessionReady current,
    MapHexCoordinate target,
    String unitId,
    int generation,
  ) async {
    _setState(
      current.withInteraction(
        current.interaction.copyWith(
          selected: target,
          clearRoute: true,
          movementPending: true,
          clearMovementError: true,
        ),
      ),
    );
    final completion = await _movement.routePlan(
      expectedRevision: current.recipient.stamp.revision,
      unitId: unitId,
      target: target,
    );
    final ready = _currentInteraction(generation);
    if (ready == null) return;
    final failure = completion.failure;
    if (failure != null) {
      _setState(_movementFailureState(ready, completion));
    } else {
      _setState(
        ready.withInteraction(
          ready.interaction.copyWith(
            route: completion.result!,
            movementPending: false,
          ),
        ),
      );
    }
  }

  void confirmMove() {
    unawaited(_confirmMove());
  }

  Future<void> _confirmMove() async {
    final current = _state;
    if (current is! GameSessionReady || _interactionBusy(current.interaction)) {
      return;
    }
    final route = current.interaction.route;
    final unitId = current.interaction.selectedUnitId;
    if (route == null || unitId == null) return;
    final generation = ++_interactionGeneration;
    _setState(
      current.withInteraction(
        current.interaction.copyWith(
          movementPending: true,
          clearMovementError: true,
        ),
      ),
    );
    final completion = await _movement.moveUnit(
      expectedRevision: current.recipient.stamp.revision,
      unitId: unitId,
      target: route.target,
    );
    final ready = _currentInteraction(generation);
    if (ready == null) return;
    if (completion.failure != null) {
      _setState(_movementFailureState(ready, completion));
    } else {
      _setState(
        _moveResultState(ready, completion.result!, unitId, route.destination),
      );
    }
  }

  void executeUnitAction(UnitActionKindView action) {
    unawaited(_executeUnitAction(action));
  }

  Future<void> _executeUnitAction(UnitActionKindView action) async {
    final current = _state;
    if (current is! GameSessionReady || _interactionBusy(current.interaction)) {
      return;
    }
    final actionDeck = current.interaction.actionDeck;
    final unitId = current.interaction.selectedUnitId;
    if (actionDeck == null || unitId == null || actionDeck.unitId != unitId) {
      return;
    }
    final generation = ++_interactionGeneration;
    final correlationId = ++_actionCorrelationId;
    _setState(
      current.withInteraction(
        current.interaction.copyWith(
          clearReachable: true,
          clearRoute: true,
          clearMovementError: true,
          actionDeck: actionDeck.copyWith(
            correlationId: correlationId,
            inFlightAction: action,
            clearFailure: true,
          ),
        ),
      ),
    );
    final completion = await _unitActions.execute(
      expectedRevision: current.recipient.stamp.revision,
      unitId: unitId,
      action: action,
    );
    final ready = _currentUnitAction(generation, correlationId);
    if (ready != null) {
      _setState(reduceUnitActionCompletion(ready, completion));
    }
  }

  void endTurn() {
    unawaited(_endTurn());
  }

  Future<void> _endTurn() async {
    final current = _state;
    if (current is! GameSessionReady ||
        current.turnAction.inFlight ||
        !current.recipient.turnView.canEndTurn) {
      return;
    }
    final correlationId = ++_turnCorrelationId;
    _setState(
      current.withTurnAction(
        current.turnAction.copyWith(
          correlationId: correlationId,
          inFlight: true,
          clearFailure: true,
        ),
      ),
    );
    final completion = await _turns.endTurn(
      expectedRevision: current.recipient.stamp.revision,
    );
    final ready = _currentTurn(correlationId);
    if (ready == null) return;
    final resynced = completion.resyncedPlayer;
    var synchronized = resynced == null ? ready : ready.withRecipient(resynced);
    final failure = completion.failure;
    if (failure != null) {
      _setState(
        synchronized.withTurnAction(
          synchronized.turnAction.copyWith(inFlight: false, failure: failure),
        ),
      );
      return;
    }
    final result = completion.result!;
    if (!result.accepted) {
      _setState(
        synchronized.withTurnAction(
          synchronized.turnAction.copyWith(
            inFlight: false,
            failure: TurnActionFailureView.rejected(result.rejectionCode!),
          ),
        ),
      );
      return;
    }
    synchronized = synchronized.withRecipient(result.player!);
    _setState(
      synchronized
          .withTurnPresentations(
            synchronized.turnPresentations.observeActivities(result.activities),
          )
          .withTurnAction(
            synchronized.turnAction.copyWith(
              inFlight: false,
              clearFailure: true,
            ),
          ),
    );
  }

  void toggleReference() {
    final current = _state;
    if (current is! GameSessionReady) return;
    _setState(
      current.withInteraction(
        current.interaction.copyWith(
          referenceVisible: !current.interaction.referenceVisible,
        ),
      ),
    );
  }

  void completeTurnPresentation() {
    if (_state case final GameSessionReady current) {
      _setState(current.completeTurnPresentation());
    }
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _loadGeneration += 1;
    _interactionGeneration += 1;
    unawaited(_session.close());
    unawaited(_changes.close());
  }

  bool _isCurrent(int generation) =>
      !_disposed && generation == _loadGeneration;

  GameSessionReady? _currentInteraction(int generation) {
    if (_disposed || generation != _interactionGeneration) return null;
    final current = _state;
    return current is GameSessionReady ? current : null;
  }

  GameSessionReady? _currentUnitAction(int generation, int correlationId) {
    final ready = _currentInteraction(generation);
    return ready?.interaction.actionDeck?.correlationId == correlationId
        ? ready
        : null;
  }

  GameSessionReady? _currentTurn(int correlationId) {
    if (_disposed) return null;
    final current = _state;
    return current is GameSessionReady &&
            current.turnAction.correlationId == correlationId
        ? current
        : null;
  }

  void _setState(GameSessionState value) {
    if (_disposed) return;
    _state = value;
    _changes.add(value);
  }
}

void _ignoreDiagnostic(String code, Object error, StackTrace stackTrace) {}

GameSessionReady _moveResultState(
  GameSessionReady current,
  MoveUnitResultView result,
  String unitId,
  MapHexCoordinate routeDestination,
) {
  if (!result.accepted) {
    return current.withInteraction(
      current.interaction.copyWith(
        movementPending: false,
        movementError: MapMovementFailure.rejected(result.rejectionCode!),
      ),
    );
  }
  final player = result.player!;
  var movedCoordinate = routeDestination;
  for (final unit in player.units) {
    if (unit.id == unitId) movedCoordinate = unit.coordinate;
  }
  return current
      .withRecipient(player)
      .withInteraction(
        current.interaction.copyWith(
          selected: movedCoordinate,
          clearSelectedUnit: true,
          clearReachable: true,
          clearRoute: true,
          clearActionDeck: true,
          movementPending: false,
          clearMovementError: true,
          lastMovementExecution: result.execution,
        ),
      );
}

GameSessionReady _movementFailureState<T>(
  GameSessionReady current,
  MovementCommandCompletion<T> completion,
) {
  final player = completion.resyncedPlayer;
  final synchronized = player == null ? current : current.withRecipient(player);
  return synchronized.withInteraction(
    synchronized.interaction.copyWith(
      movementPending: false,
      movementError: completion.failure!,
    ),
  );
}

bool _interactionBusy(MapInteractionState interaction) =>
    interaction.movementPending ||
    (interaction.actionDeck?.commandPending ?? false);

MapLoadFailureViewCode _loadFailureCode(String code) => switch (code) {
  'rust_adapter_unavailable' ||
  'rust_unavailable' => MapLoadFailureViewCode.adapterUnavailable,
  'rust_capability_mismatch' ||
  'invalid_map_protocol' => MapLoadFailureViewCode.incompatibleClient,
  'map_load_superseded' => MapLoadFailureViewCode.loadSuperseded,
  _ => MapLoadFailureViewCode.mapUnavailable,
};
