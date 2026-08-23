import 'dart:async';

import 'package:flutter/foundation.dart';

import '../read_model/map_scene.dart';
import '../read_model/map_view.dart';
import '../read_model/movement_view.dart';
import 'map_interaction_state.dart';
import 'map_repository.dart';

sealed class MapScreenState {
  const MapScreenState();
}

final class MapLoadingState extends MapScreenState {
  const MapLoadingState();
}

final class MapReadyState extends MapScreenState {
  const MapReadyState({required this.scene, required this.interaction});

  final MapScene scene;
  final MapInteractionState interaction;

  MapReadyState withInteraction(MapInteractionState value) =>
      MapReadyState(scene: scene, interaction: value);
}

final class MapFailureState extends MapScreenState {
  const MapFailureState({required this.code, required this.message});

  final String code;
  final String message;
}

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
  MapScreenState _state = const MapLoadingState();
  var _disposed = false;
  var _loadGeneration = 0;
  var _interactionGeneration = 0;

  MapScreenState get state => _state;

  Future<void> load() async {
    if (_disposed) return;
    final generation = ++_loadGeneration;
    _interactionGeneration += 1;
    _setState(const MapLoadingState());
    try {
      final scene = await _repository.load(assets);
      if (!_isCurrent(generation)) return;
      _setState(
        MapReadyState(scene: scene, interaction: const MapInteractionState()),
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
      _setState(MapFailureState(code: error.code, message: error.message));
    } on Object catch (error, stackTrace) {
      if (!_isCurrent(generation)) return;
      _diagnosticReporter('unexpected_map_failure', error, stackTrace);
      _setState(
        const MapFailureState(
          code: 'unexpected_map_failure',
          message: 'The map could not be loaded.',
        ),
      );
    }
  }

  void hover(MapHexCoordinate? coordinate) {
    final current = _state;
    if (current is! MapReadyState) return;
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
    if (current is! MapReadyState || current.interaction.movementPending) {
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

    final unit = current.scene.player.controlledUnitAt(next);
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

  void _clearSelection(MapReadyState current) {
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

  void _selectPlainHex(MapReadyState current, MapHexCoordinate coordinate) {
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
    MapReadyState current,
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
        expectedRevision: current.scene.player.stamp.revision,
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
    MapReadyState current,
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
        expectedRevision: current.scene.player.stamp.revision,
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
    if (current is! MapReadyState || current.interaction.movementPending) {
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
        expectedRevision: current.scene.player.stamp.revision,
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
    if (current is! MapReadyState) return;
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
    _disposed = true;
    _loadGeneration += 1;
    _interactionGeneration += 1;
    unawaited(_repository.close());
    super.dispose();
  }

  bool _isCurrent(int generation) =>
      !_disposed && generation == _loadGeneration;

  MapReadyState? _currentInteraction(int generation) {
    if (_disposed || generation != _interactionGeneration) return null;
    final current = _state;
    return current is MapReadyState ? current : null;
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

  void _setState(MapScreenState value) {
    if (_disposed) return;
    _state = value;
    notifyListeners();
  }
}

MapReadyState _moveResultState(
  MapReadyState current,
  MoveUnitResultView result,
  String unitId,
  MapHexCoordinate routeDestination,
) {
  if (!result.accepted) {
    return current.withInteraction(
      current.interaction.copyWith(
        movementPending: false,
        movementError: 'Move rejected: ${result.rejectionCode}',
      ),
    );
  }
  final player = result.player!;
  var movedCoordinate = routeDestination;
  for (final unit in player.units) {
    if (unit.id == unitId) movedCoordinate = unit.coordinate;
  }
  return MapReadyState(
    scene: current.scene.withPlayer(player),
    interaction: current.interaction.copyWith(
      selected: movedCoordinate,
      clearSelectedUnit: true,
      clearReachable: true,
      clearRoute: true,
      movementPending: false,
      clearMovementError: true,
    ),
  );
}
