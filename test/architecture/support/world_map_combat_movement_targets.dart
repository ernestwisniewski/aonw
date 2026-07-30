part of '../world_map_combat_boundary_test.dart';

const _movementTargets = [
  _Target(
    path:
        'packages/aonw_core/lib/game/domain/movement/'
        'domain_move_unit_resolver.dart',
    owner: 'DomainMoveUnitResolver',
    boundaries: [
      _Boundary.method(
        'resolve',
        parameter: 'mapData',
        type: 'MapTraversalView',
      ),
    ],
  ),
  _Target(
    path:
        'packages/aonw_core/lib/game/domain/movement/'
        'movement_command_executor.dart',
    owner: 'MovementCommandExecutor',
    boundaries: [
      _Boundary.method(
        'execute',
        parameter: 'mapData',
        type: 'MapTraversalView',
      ),
    ],
  ),
  _Target(
    path:
        'packages/aonw_core/lib/game/domain/movement/'
        'movement_command_guard.dart',
    owner: 'MovementCommandGuard',
    boundaries: [
      _Boundary.method(
        'validate',
        parameter: 'mapData',
        type: 'MapTraversalView',
      ),
      _Boundary.method(
        'canCarryArtifactIntoTargetCity',
        parameter: 'targetTile',
        type: 'MapTileView',
      ),
    ],
  ),
  _Target(
    path:
        'packages/aonw_core/lib/game/domain/movement/'
        'movement_command_planner.dart',
    owner: 'MovementCommandPlanner',
    boundaries: [
      _Boundary.method(
        'resolve',
        parameter: 'mapData',
        type: 'MapTraversalView',
      ),
    ],
  ),
  _Target(
    path:
        'packages/aonw_core/lib/game/domain/movement/'
        'movement_command_resolver.dart',
    owner: 'MovementCommandResolver',
    boundaries: [
      _Boundary.method(
        'resolve',
        parameter: 'mapData',
        type: 'MapTraversalView',
      ),
    ],
  ),
  _Target(
    path: 'lib/game/domain/movement/unit_movement_planner.dart',
    owner: 'UnitMovementPlanner',
    boundaries: [
      _Boundary.constructor('', parameter: 'mapData', type: 'MapTraversalView'),
      _Boundary.method(
        'planMove',
        parameter: 'targetTile',
        type: 'MapTileView',
      ),
    ],
  ),
  _Target(
    path: 'lib/game/domain/movement/unit_movement_turn_rules.dart',
    owner: 'UnitMovementTurnRules',
    boundaries: [
      _Boundary.method(
        'validateQueuedPath',
        parameter: 'mapData',
        type: 'MapTraversalView',
      ),
    ],
  ),
  _Target(
    path: 'lib/game/domain/reducer/movement/movement_reducer.dart',
    owner: 'MovementReducer',
    boundaries: [
      _Boundary.method(
        'handleMoveTargetTileWithEnvironment',
        parameter: 'targetTile',
        type: 'MapTileView',
      ),
      _Boundary.method(
        'handleMoveTargetTile',
        parameter: 'mapView',
        type: 'MapTraversalView',
      ),
      _Boundary.method(
        'resetUnitMovementForNewTurn',
        parameter: 'mapView',
        type: 'MapTraversalView',
      ),
      _Boundary.method(
        '_selectUpdatedUnit',
        parameter: 'mapTiles',
        type: 'MapTileLookup',
      ),
      _Boundary.method(
        '_canCarryArtifactIntoTargetCity',
        parameter: 'targetTile',
        type: 'MapTileView',
      ),
    ],
  ),
  _Target(
    path:
        'lib/game/domain/reducer/movement/'
        'movement_selection_projector.dart',
    owner: '_MoveSelection',
    boundaries: [
      _Boundary.method('forUnit', parameter: 'mapTiles', type: 'MapTileLookup'),
    ],
  ),
  _Target(
    path:
        'lib/game/domain/reducer/movement/'
        'movement_reducer_auto_explore.dart',
    owner: '_AutoExploreProcessor',
    boundaries: [
      _Boundary.method(
        'advanceForNewTurn',
        parameter: 'mapView',
        type: 'MapTraversalView',
      ),
    ],
  ),
  _Target(
    path:
        'lib/game/domain/reducer/movement/'
        'movement_reducer_turn_reset.dart',
    owner: '_MovementTurnResetProcessor',
    boundaries: [
      _Boundary.method('run', parameter: 'mapView', type: 'MapTraversalView'),
      _Boundary.method(
        '_replanQueuedPath',
        parameter: 'mapView',
        type: 'MapTraversalView',
      ),
      _Boundary.method(
        '_planQueuedPath',
        parameter: 'mapView',
        type: 'MapTraversalView',
      ),
      _Boundary.method(
        '_refreshSelectedUnit',
        parameter: 'mapTiles',
        type: 'MapTileLookup',
      ),
    ],
  ),
  _Target(
    path:
        'lib/game/domain/reducer/movement/'
        'movement_reducer_move_preview.dart',
    owner: '_MovePreviewReducer',
    boundaries: [
      _Boundary.method(
        'setPreview',
        parameter: 'mapView',
        type: 'MapTraversalView',
      ),
      _Boundary.method(
        'confirmPreview',
        parameter: 'mapView',
        type: 'MapTraversalView',
      ),
      _Boundary.method(
        '_planPreview',
        parameter: 'mapView',
        type: 'MapTraversalView',
      ),
      _Boundary.method(
        '_blockedFeedback',
        parameter: 'targetTile',
        type: 'MapTileView',
      ),
    ],
  ),
];
