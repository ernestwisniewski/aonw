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
    path: 'lib/game/domain/reducer/combat/combat_reducer.dart',
    owner: 'CombatReducer',
    boundaries: [
      _Boundary.method(
        'selectAttackTarget',
        parameter: 'mapTiles',
        type: 'MapTileLookup',
      ),
    ],
  ),
  _Target(
    path: 'lib/game/domain/reducer/combat/combat_reducer_targeting.dart',
    owner: '_CombatTargetingPolicy',
    boundaries: [
      _Boundary.method(
        'unitTarget',
        parameter: 'mapTiles',
        type: 'MapTileLookup',
      ),
      _Boundary.method(
        'cityTarget',
        parameter: 'mapTiles',
        type: 'MapTileLookup',
      ),
      _Boundary.method(
        '_attackerForTargeting',
        parameter: 'mapTiles',
        type: 'MapTileLookup',
      ),
    ],
  ),
  _Target(
    path:
        'packages/aonw_core/lib/game/domain/combat/'
        'combat_command_resolver.dart',
    owner: 'CombatCommandResolver',
    boundaries: [
      _Boundary.method('resolve', parameter: 'mapTiles', type: 'MapTileLookup'),
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
