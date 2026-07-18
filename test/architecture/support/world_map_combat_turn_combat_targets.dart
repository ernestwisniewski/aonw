part of '../world_map_combat_boundary_test.dart';

const _turnCombatTargets = [
  _Target(
    path: 'lib/game/domain/reducer/turn/turn_reducer.dart',
    owner: 'TurnReducer',
    boundaries: [
      _Boundary.method(
        'focusNextPendingAction',
        parameter: 'mapTiles',
        type: 'MapTileLookup',
      ),
      _Boundary.method(
        'focusTurnStartAction',
        parameter: 'mapTiles',
        type: 'MapTileLookup',
      ),
      _Boundary.method(
        '_turnStartProductionEffects',
        parameter: 'mapTiles',
        type: 'MapTileLookup',
      ),
      _Boundary.method(
        '_turnsRemainingForQueue',
        parameter: 'mapTiles',
        type: 'MapTileLookup',
      ),
      _Boundary.method(
        '_productionPerTurnForQueue',
        parameter: 'mapTiles',
        type: 'MapTileLookup',
      ),
      _Boundary.method(
        'pendingTurnActionCount',
        parameter: 'mapTiles',
        type: 'MapTileLookup',
      ),
      _Boundary.method(
        'pendingTurnActionTargets',
        parameter: 'mapTiles',
        type: 'MapTileLookup',
      ),
      _Boundary.method(
        'currentPendingTurnActionIndex',
        parameter: 'mapTiles',
        type: 'MapTileLookup',
      ),
      _Boundary.method(
        '_focusUnitAction',
        parameter: 'mapTiles',
        type: 'MapTileLookup',
      ),
      _Boundary.method(
        '_focusPendingTurnAction',
        parameter: 'mapTiles',
        type: 'MapTileLookup',
      ),
      _Boundary.method(
        '_focusCityProductionAction',
        parameter: 'mapTiles',
        type: 'MapTileLookup',
      ),
      _Boundary.method(
        '_pendingTurnActions',
        parameter: 'mapTiles',
        type: 'MapTileLookup',
      ),
    ],
  ),
  _Target(
    path: 'lib/game/domain/reducer/turn/end_turn_reducer.dart',
    owner: 'EndTurnReducer',
    boundaries: [
      _Boundary.method(
        'advanceCitiesForPlayer',
        parameter: 'mapView',
        type: 'MapReadView',
      ),
    ],
  ),
  _Target(
    path: 'lib/game/domain/reducer/combat/combat_reducer.dart',
    owner: 'CombatReducer',
    boundaries: [
      _Boundary.method(
        'selectAttackTarget',
        parameter: 'mapTiles',
        type: 'MapTileLookup',
      ),
      _Boundary.method(
        'attackHex',
        parameter: 'mapTiles',
        type: 'MapTileLookup',
      ),
      _Boundary.method(
        '_attackCity',
        parameter: 'mapTiles',
        type: 'MapTileLookup',
      ),
      _Boundary.method(
        '_recordIntent',
        parameter: 'mapTiles',
        type: 'MapTileLookup',
      ),
      _Boundary.method(
        '_clearAttackInteractionState',
        parameter: 'mapTiles',
        type: 'MapTileLookup',
      ),
      _Boundary.method(
        '_refreshSelection',
        parameter: 'mapTiles',
        type: 'MapTileLookup',
      ),
      _Boundary.method(
        '_refreshUnit',
        parameter: 'mapTiles',
        type: 'MapTileLookup',
      ),
    ],
  ),
  _Target(
    path: 'lib/game/domain/reducer/combat/combat_reducer_setup.dart',
    owner: '_CombatSetupFactory',
    boundaries: [
      _Boundary.method(
        'unitAttackSetup',
        parameter: 'mapTiles',
        type: 'MapTileLookup',
      ),
      _Boundary.method(
        'cityAttackSetup',
        parameter: 'mapTiles',
        type: 'MapTileLookup',
      ),
      _Boundary.method(
        'defenseSetup',
        parameter: 'mapTiles',
        type: 'MapTileLookup',
      ),
      _Boundary.method(
        '_attackerCombatSetup',
        parameter: 'mapTiles',
        type: 'MapTileLookup',
      ),
    ],
  ),
  _Target(
    path: 'lib/game/domain/reducer/combat/combat_reducer_fog.dart',
    owner: '_CombatFogPolicy',
    boundaries: [
      _Boundary.method(
        'recomputeAfterCombat',
        parameter: 'mapTiles',
        type: 'MapTileLookup',
      ),
    ],
  ),
  _Target(
    path: 'lib/game/domain/turn/turn_context.dart',
    owner: 'TurnContext',
    boundaries: [
      _Boundary.constructor(
        '',
        parameter: 'mapTiles',
        type: 'MapTileLookup',
        requireField: false,
      ),
    ],
  ),
  _Target(
    path:
        'packages/aonw_core/lib/game/domain/turn/persistent_turn_combat_resolver.dart',
    owner: 'PersistentTurnCombatResolver',
    boundaries: [
      _Boundary.method(
        'resolve',
        parameter: 'mapTiles',
        type: 'MapTileLookup',
        nullable: true,
      ),
    ],
  ),
  _Target(
    path:
        'packages/aonw_core/lib/game/domain/combat/persistent_combat_command_resolver.dart',
    owner: 'PersistentCombatCommandResolver',
    boundaries: [
      _Boundary.method('resolve', parameter: 'mapTiles', type: 'MapTileLookup'),
    ],
  ),
  _Target(
    path:
        'packages/aonw_core/lib/game/domain/turn/persistent_turn_pipeline.dart',
    owner: 'PersistentTurnPipelineRequest',
    boundaries: [
      _Boundary.constructor(
        'simultaneousFinalize',
        parameter: 'mapView',
        type: 'MapReadView',
      ),
    ],
  ),
  _Target(
    path:
        'packages/aonw_core/lib/game/domain/turn/persistent_turn_pipeline.dart',
    owner: 'PersistentTurnPipeline',
    boundaries: [
      _Boundary.method(
        'advancePlayer',
        parameter: 'mapView',
        type: 'MapReadView',
      ),
    ],
  ),
  _Target(
    path:
        'packages/aonw_core/lib/game/domain/turn/'
        'persistent_turn_economy_processor.dart',
    owner: 'PersistentTurnEconomyProcessor',
    boundaries: [
      _Boundary.method(
        'advanceForPlayers',
        parameter: 'mapData',
        type: 'MapReadView',
      ),
    ],
  ),
  _Target(
    path:
        'packages/aonw_core/lib/game/domain/turn/'
        'domain_turn_economy_processor.dart',
    owner: 'DomainTurnEconomyProcessor',
    boundaries: [
      _Boundary.method(
        'advanceForPlayers',
        parameter: 'mapData',
        type: 'MapReadView',
      ),
    ],
  ),
  _Target(
    path:
        'packages/aonw_core/lib/game/domain/turn/economy/'
        'turn_economy_context.dart',
    owner: 'TurnEconomyContext',
    boundaries: [
      _Boundary.constructor('', parameter: 'mapData', type: 'MapReadView'),
    ],
  ),
];
