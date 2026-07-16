part of '../world_map_combat_boundary_test.dart';

const _movementTargets = [
  _Target(
    path:
        'packages/aonw_core/lib/game/domain/movement/persistent_move_unit_resolver.dart',
    owner: 'PersistentMoveUnitResolver',
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
        'persistent_merchant_trade_route_resolver.dart',
    owner: 'PersistentMerchantTradeRouteResolver',
    boundaries: [
      _Boundary.method(
        'assignRoute',
        parameter: 'mapData',
        type: 'MapTraversalView',
      ),
      _Boundary.method(
        'moveToCity',
        parameter: 'mapData',
        type: 'MapTraversalView',
      ),
    ],
  ),
  _Target(
    path:
        'packages/aonw_core/lib/game/domain/movement/persistent_unit_action_resolver.dart',
    owner: 'PersistentUnitActionResolver',
    boundaries: [
      _Boundary.method(
        'autoExploreUnit',
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
        'resetForNewTurn',
        parameter: 'mapData',
        type: 'MapTileLookup',
        nullable: true,
      ),
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
        'moveUnit',
        parameter: 'mapView',
        type: 'MapTraversalView',
      ),
      _Boundary.method(
        'autoExploreUnit',
        parameter: 'mapView',
        type: 'MapTraversalView',
      ),
      _Boundary.method(
        'resetUnitMovementForNewTurn',
        parameter: 'mapView',
        type: 'MapTraversalView',
      ),
      _Boundary.method(
        'cancelUnitAction',
        parameter: 'mapTiles',
        type: 'MapTileLookup',
      ),
      _Boundary.method(
        'skipUnitTurn',
        parameter: 'mapTiles',
        type: 'MapTileLookup',
      ),
      _Boundary.method(
        'fortifyUnit',
        parameter: 'mapTiles',
        type: 'MapTileLookup',
      ),
      _Boundary.method(
        '_queueMovePath',
        parameter: 'mapTiles',
        type: 'MapTileLookup',
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
        'movement_reducer_direct_move.dart',
    owner: '_DirectMoveProcessor',
    boundaries: [
      _Boundary.method('run', parameter: 'mapView', type: 'MapTraversalView'),
      _Boundary.method(
        '_validTargetTile',
        parameter: 'mapTiles',
        type: 'MapTileLookup',
      ),
      _Boundary.method(
        '_canTraverseEventually',
        parameter: 'targetTile',
        type: 'MapTileView',
      ),
      _Boundary.method(
        '_applyExecutedMove',
        parameter: 'mapTiles',
        type: 'MapTileLookup',
      ),
    ],
  ),
  _Target(
    path:
        'lib/game/domain/reducer/movement/'
        'movement_reducer_auto_explore.dart',
    owner: '_AutoExploreProcessor',
    boundaries: [
      _Boundary.method('run', parameter: 'mapView', type: 'MapTraversalView'),
      _Boundary.method(
        'advanceForNewTurn',
        parameter: 'mapView',
        type: 'MapTraversalView',
      ),
      _Boundary.method(
        '_commandFor',
        parameter: 'mapView',
        type: 'MapTraversalView',
      ),
      _Boundary.method(
        'keepPosture',
        parameter: 'mapTiles',
        type: 'MapTileLookup',
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
        '_refreshSelectedUnit',
        parameter: 'mapTiles',
        type: 'MapTileLookup',
      ),
    ],
  ),
  _Target(
    path:
        'lib/game/domain/reducer/movement/'
        'movement_reducer_direct_move.dart',
    owner: '_DirectMovePlanFinder',
    boundaries: [
      _Boundary.constructor('', parameter: 'mapView', type: 'MapTraversalView'),
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
        '_blockedFeedback',
        parameter: 'targetTile',
        type: 'MapTileView',
      ),
    ],
  ),
  _Target(
    path:
        'lib/game/domain/reducer/movement/'
        'movement_reducer_unit_action_state.dart',
    owner: '_UnitActionStateCleanup',
    boundaries: [
      _Boundary.constructor('', parameter: 'mapTiles', type: 'MapTileLookup'),
    ],
  ),
];
