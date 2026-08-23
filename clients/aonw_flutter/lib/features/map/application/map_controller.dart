import 'dart:async';

import 'package:flutter/foundation.dart';

import '../read_model/map_view.dart';
import '../read_model/movement_view.dart';
import 'game_session_state.dart';
import 'map_interaction_state.dart';
import 'map_repository.dart';

typedef MapDiagnosticReporter =
    void Function(String code, Object error, StackTrace stackTrace);

void _reportMapDiagnostic(String code, Object error, StackTrace stackTrace) {
  debugPrintStack(
    label: 'Map load diagnostic [$code]: $error',
    stackTrace: stackTrace,
  );
}

final class MapController extends ChangeNotifier {
  MapController({
    required MapRepository repository,
    this.assets = MapAssetPaths.starter,
    MapDiagnosticReporter diagnosticReporter = _reportMapDiagnostic,
  }) : _repository = repository,
       _diagnosticReporter = diagnosticReporter;

  final MapRepository _repository;
  final MapDiagnosticReporter _diagnosticReporter;
  final MapAssetPaths assets;
  GameSessionState _state = const GameSessionLoading();
  var _disposed = false;
  var _loadGeneration = 0;
  var _interactionGeneration = 0;

  GameSessionState get state => _state;

  Future<void> load() async {
    if (_disposed) return;
    final generation = ++_loadGeneration;
    _interactionGeneration += 1;
    _setState(const GameSessionLoading());
    try {
      final scene = await _repository.load(assets);
      if (!_isCurrent(generation)) return;
      _setState(
        GameSessionReady(
          scene: scene,
          interaction: const MapInteractionState(),
        ),
      );
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
      _setState(GameSessionFailure(code: error.code, message: error.message));
    } on Object catch (error, stackTrace) {
      if (!_isCurrent(generation)) return;
      _diagnosticReporter('unexpected_map_failure', error, stackTrace);
      _setState(
        const GameSessionFailure(
          code: 'unexpected_map_failure',
          message: 'The map could not be loaded.',
        ),
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
    if (current is! GameSessionReady || current.interaction.movementPending) {
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
          clearReachable: true,
          clearRoute: true,
          movementPending: true,
          clearMovementError: true,
        ),
      ),
    );
    try {
      final reachable = await _repository.reachable(
        expectedRevision: current.recipient.stamp.revision,
        unitId: unitId,
      );
      final ready = _currentInteraction(generation);
      if (ready == null) return;
      _setState(
        ready.withInteraction(
          ready.interaction.copyWith(
            reachable: reachable,
            movementPending: false,
          ),
        ),
      );
    } on MapSessionException catch (error, stackTrace) {
      _handleMovementFailure(generation, error, stackTrace);
    } on Object catch (error, stackTrace) {
      _handleUnexpectedMovementFailure(generation, error, stackTrace);
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
    try {
      final route = await _repository.routePlan(
        expectedRevision: current.recipient.stamp.revision,
        unitId: unitId,
        target: target,
      );
      final ready = _currentInteraction(generation);
      if (ready == null) return;
      _setState(
        ready.withInteraction(
          ready.interaction.copyWith(route: route, movementPending: false),
        ),
      );
    } on MapSessionException catch (error, stackTrace) {
      _handleMovementFailure(generation, error, stackTrace);
    } on Object catch (error, stackTrace) {
      _handleUnexpectedMovementFailure(generation, error, stackTrace);
    }
  }

  void confirmMove() {
    unawaited(_confirmMove());
  }

  Future<void> _confirmMove() async {
    final current = _state;
    if (current is! GameSessionReady || current.interaction.movementPending) {
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
    try {
      final result = await _repository.moveUnit(
        expectedRevision: current.recipient.stamp.revision,
        unitId: unitId,
        target: route.target,
      );
      final ready = _currentInteraction(generation);
      if (ready == null) return;
      _setState(_moveResultState(ready, result, unitId, route.destination));
    } on MapSessionException catch (error, stackTrace) {
      _handleMovementFailure(generation, error, stackTrace);
    } on Object catch (error, stackTrace) {
      _handleUnexpectedMovementFailure(generation, error, stackTrace);
    }
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

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _loadGeneration += 1;
    _interactionGeneration += 1;
    unawaited(_repository.close());
    super.dispose();
  }

  bool _isCurrent(int generation) =>
      !_disposed && generation == _loadGeneration;

  GameSessionReady? _currentInteraction(int generation) {
    if (_disposed || generation != _interactionGeneration) return null;
    final current = _state;
    return current is GameSessionReady ? current : null;
  }

  void _handleMovementFailure(
    int generation,
    MapSessionException error,
    StackTrace stackTrace,
  ) {
    final ready = _currentInteraction(generation);
    if (ready == null) return;
    final cause = error.diagnosticCause;
    if (cause != null) {
      _diagnosticReporter(
        error.code,
        cause,
        error.diagnosticStackTrace ?? stackTrace,
      );
    }
    _setState(
      ready.withInteraction(
        ready.interaction.copyWith(
          movementPending: false,
          movementError: error.message,
        ),
      ),
    );
  }

  void _handleUnexpectedMovementFailure(
    int generation,
    Object error,
    StackTrace stackTrace,
  ) {
    final ready = _currentInteraction(generation);
    if (ready == null) return;
    _diagnosticReporter('unexpected_movement_failure', error, stackTrace);
    _setState(
      ready.withInteraction(
        ready.interaction.copyWith(
          movementPending: false,
          movementError: 'The movement request failed.',
        ),
      ),
    );
  }

  void _setState(GameSessionState value) {
    if (_disposed) return;
    _state = value;
    notifyListeners();
  }
}

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
        movementError: 'Move rejected: ${result.rejectionCode!.wireCode}',
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
          movementPending: false,
          clearMovementError: true,
        ),
      );
}
