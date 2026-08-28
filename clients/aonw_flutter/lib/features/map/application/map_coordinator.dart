import 'dart:async';

import '../../artifacts/application/artifact_session_port.dart';
import '../../artifacts/application/artifact_state.dart';
import '../../artifacts/application/artifact_workflow.dart';
import '../../artifacts/read_model/artifact_view.dart';
import '../../cities/application/city_session_port.dart';
import '../../cities/application/city_state.dart';
import '../../cities/application/city_workflow.dart';
import '../../cities/read_model/city_view.dart';
import '../../combat/application/combat_session_port.dart';
import '../../combat/application/combat_workflow.dart';
import '../../combat/read_model/combat_view.dart';
import '../../logistics/application/unit_logistics_session_port.dart';
import '../../logistics/application/unit_logistics_state.dart';
import '../../logistics/application/unit_logistics_workflow.dart';
import '../../logistics/read_model/unit_logistics_view.dart';
import '../../production/application/production_session_port.dart';
import '../../production/application/production_state.dart';
import '../../production/application/production_workflow.dart';
import '../../production/read_model/production_view.dart';
import '../../turns/application/turn_session_port.dart';
import '../../turns/application/turn_workflow.dart';
import '../../unit_actions/application/action_deck_state.dart';
import '../../unit_actions/application/unit_action_command_runner.dart';
import '../../unit_actions/application/unit_action_session_port.dart';
import '../../unit_actions/read_model/unit_action_view.dart';
import '../../workers/application/worker_session_port.dart';
import '../../workers/application/worker_state.dart';
import '../../workers/application/worker_workflow.dart';
import '../../workers/read_model/worker_view.dart';
import '../read_model/map_view.dart';
import '../read_model/movement_view.dart';
import '../read_model/player_map_view.dart';
import 'game_session_state.dart';
import 'map_interaction_state.dart';
import 'map_session_port.dart';
import 'movement_command_runner.dart';
import 'movement_session_port.dart';
import 'unit_action_workflow.dart';

part 'map_coordinator_actions.dart';
part 'map_coordinator_selection.dart';

typedef MapDiagnosticReporter =
    void Function(String code, Object error, StackTrace stackTrace);

final class MapCoordinator {
  MapCoordinator({
    required MapSessionPort session,
    required MovementSessionPort movement,
    CombatSessionPort? combat,
    CitySessionPort? cities,
    required UnitLogisticsSessionPort logistics,
    WorkerSessionPort? workers,
    ProductionSessionPort? production,
    ArtifactSessionPort? artifacts,
    required UnitActionSessionPort unitActions,
    required TurnSessionPort turns,
    this.assets = MapAssetPaths.starter,
    MapDiagnosticReporter? diagnosticReporter,
  }) : _session = session,
       _movement = MovementCommandRunner(
         session: movement,
         diagnosticReporter: diagnosticReporter ?? _ignoreDiagnostic,
       ),
       _combat = CombatWorkflow(
         session: combat ?? _requireCombatSession(movement),
         diagnosticReporter: diagnosticReporter ?? _ignoreDiagnostic,
       ),
       _cities = CityWorkflow(
         session: cities ?? _requireCitySession(movement),
         diagnosticReporter: diagnosticReporter ?? _ignoreDiagnostic,
       ),
       _logistics = UnitLogisticsWorkflow(
         session: logistics,
         diagnosticReporter: diagnosticReporter ?? _ignoreDiagnostic,
       ),
       _workers = WorkerWorkflow(
         session: workers ?? _requireWorkerSession(movement),
         diagnosticReporter: diagnosticReporter ?? _ignoreDiagnostic,
       ),
       _production = ProductionWorkflow(
         session: production ?? _requireProductionSession(movement),
         diagnosticReporter: diagnosticReporter ?? _ignoreDiagnostic,
       ),
       _artifacts = ArtifactWorkflow(
         session: artifacts ?? _requireArtifactSession(movement),
         diagnosticReporter: diagnosticReporter ?? _ignoreDiagnostic,
       ),
       _unitActions = UnitActionWorkflow(
         runner: UnitActionCommandRunner(
           session: unitActions,
           diagnosticReporter: diagnosticReporter ?? _ignoreDiagnostic,
         ),
       ),
       _turns = TurnWorkflow(
         session: turns,
         diagnosticReporter: diagnosticReporter ?? _ignoreDiagnostic,
       ),
       _diagnosticReporter = diagnosticReporter ?? _ignoreDiagnostic;

  final MapSessionPort _session;
  final MovementCommandRunner _movement;
  final CombatWorkflow _combat;
  final CityWorkflow _cities;
  final UnitLogisticsWorkflow _logistics;
  final WorkerWorkflow _workers;
  final ProductionWorkflow _production;
  final ArtifactWorkflow _artifacts;
  final UnitActionWorkflow _unitActions;
  final TurnWorkflow _turns;
  final MapDiagnosticReporter _diagnosticReporter;
  final MapAssetPaths assets;
  final StreamController<GameSessionState> _changes =
      StreamController<GameSessionState>.broadcast(sync: true);
  GameSessionState _state = const GameSessionLoading();
  var _disposed = false;
  var _loadGeneration = 0;
  var _interactionGeneration = 0;

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
    final updated = _hoverState(current, coordinate);
    if (updated != null) _setState(updated);
  }

  void select(MapHexCoordinate? coordinate) {
    unawaited(_select(coordinate));
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

  void _setState(GameSessionState value) {
    if (_disposed) return;
    _state = value;
    _changes.add(value);
  }
}

void _ignoreDiagnostic(String code, Object error, StackTrace stackTrace) {}

GameSessionReady? _hoverState(
  GameSessionReady current,
  MapHexCoordinate? coordinate,
) {
  final next = coordinate != null && current.scene.map.contains(coordinate)
      ? coordinate
      : null;
  if (next == current.interaction.hovered) return null;
  return current.withInteraction(
    current.interaction.copyWith(hovered: next, clearHovered: next == null),
  );
}

GameSessionReady _toggleReferenceState(GameSessionReady current) =>
    current.withInteraction(
      current.interaction.copyWith(
        referenceVisible: !current.interaction.referenceVisible,
      ),
    );

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
          clearUnitLogistics: true,
          clearWorker: true,
          clearProduction: true,
          clearArtifact: true,
          clearCombat: true,
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
    (interaction.combat?.commandPending ?? false) ||
    (interaction.combat?.loading ?? false) ||
    (interaction.city?.commandPending ?? false) ||
    (interaction.city?.loading ?? false) ||
    (interaction.actionDeck?.commandPending ?? false) ||
    (interaction.unitLogistics?.commandPending ?? false) ||
    (interaction.worker?.commandPending ?? false) ||
    (interaction.worker?.loading ?? false) ||
    (interaction.production?.commandPending ?? false) ||
    (interaction.production?.loading ?? false) ||
    (interaction.artifact?.commandPending ?? false);

CombatSessionPort _requireCombatSession(MovementSessionPort movement) {
  if (movement case final CombatSessionPort combat) return combat;
  throw ArgumentError.value(
    movement,
    'movement',
    'must also provide the combat session port',
  );
}

CitySessionPort _requireCitySession(MovementSessionPort movement) {
  if (movement case final CitySessionPort cities) return cities;
  throw ArgumentError.value(
    movement,
    'movement',
    'must also provide the city session port',
  );
}

WorkerSessionPort _requireWorkerSession(MovementSessionPort movement) {
  if (movement case final WorkerSessionPort workers) return workers;
  throw ArgumentError.value(
    movement,
    'movement',
    'must also provide the worker session port',
  );
}

ProductionSessionPort _requireProductionSession(MovementSessionPort movement) {
  if (movement case final ProductionSessionPort production) return production;
  throw ArgumentError.value(
    movement,
    'movement',
    'must also provide the production session port',
  );
}

ArtifactSessionPort _requireArtifactSession(MovementSessionPort movement) {
  if (movement case final ArtifactSessionPort artifacts) return artifacts;
  throw ArgumentError.value(
    movement,
    'movement',
    'must also provide the artifact session port',
  );
}

MapLoadFailureViewCode _loadFailureCode(String code) => switch (code) {
  'rust_adapter_unavailable' ||
  'rust_unavailable' => MapLoadFailureViewCode.adapterUnavailable,
  'rust_capability_mismatch' ||
  'invalid_map_protocol' => MapLoadFailureViewCode.incompatibleClient,
  'map_load_superseded' => MapLoadFailureViewCode.loadSuperseded,
  _ => MapLoadFailureViewCode.mapUnavailable,
};
