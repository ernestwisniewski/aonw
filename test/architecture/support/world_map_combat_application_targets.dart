part of '../world_map_combat_boundary_test.dart';

const _applicationTargets = [
  _Target(
    path:
        'lib/game/application/services/'
        'ai_turn_preparation_builder.dart',
    owner: 'AiTurnPreparationBuilder',
    boundaries: [
      _Boundary.constructor('', parameter: 'mapData', type: 'MapReadView'),
    ],
  ),
  _Target(
    path: 'lib/game/application/use_cases/run_ai_turn_use_case.dart',
    owner: 'RunAiTurnUseCase',
    boundaries: [
      _Boundary.constructor('', parameter: 'mapData', type: 'MapReadView'),
    ],
  ),
  _Target(
    path: 'tool/run_save_ai_benchmark.dart',
    owner: '_PreparedPlayer',
    boundaries: [
      _Boundary.constructor(
        'fromSnapshot',
        parameter: 'mapView',
        type: 'MapReadView',
        requireField: false,
      ),
    ],
  ),
  _Target(
    path: 'tool/run_save_ai_benchmark/multi_turn_replay.dart',
    owner: '_MultiTurnReplayRunner',
    boundaries: [
      _Boundary.constructor('', parameter: 'mapView', type: 'MapReadView'),
    ],
  ),
  _Target(
    path: 'tool/run_save_ai_benchmark/runtime_smoke.dart',
    owner: '_RuntimeUseCaseSmokeRunner',
    boundaries: [
      _Boundary.constructor('', parameter: 'mapView', type: 'MapReadView'),
    ],
  ),
  _Target(
    path: 'tool/run_save_ai_benchmark/runtime_smoke.dart',
    owner: '_RuntimeSmokeCommandTransport',
    boundaries: [
      _Boundary.constructor('', parameter: 'mapView', type: 'MapReadView'),
    ],
  ),
  _Target(
    path: 'lib/game/domain/ai/pressure_target_resolver.dart',
    owner: 'PressureTargetResolver',
    boundaries: [
      _Boundary.method(
        'resolve',
        parameter: 'mapObjectives',
        type: 'Iterable<MapObjectiveDefinition>',
      ),
      _Boundary.method(
        '_scoreRaceFor',
        parameter: 'mapObjectives',
        type: 'Iterable<MapObjectiveDefinition>',
      ),
    ],
  ),
  _Target(
    path:
        'packages/aonw_core/lib/game/domain/outcome/'
        'score_race_analyzer.dart',
    owner: 'ScoreRaceAnalyzer',
    boundaries: [
      _Boundary.method(
        'analyzeForPlayer',
        parameter: 'mapObjectives',
        type: 'Iterable<MapObjectiveDefinition>',
      ),
      _Boundary.method(
        'pressureTargetPlayerIds',
        parameter: 'mapObjectives',
        type: 'Iterable<MapObjectiveDefinition>',
      ),
      _Boundary.method(
        '_breakdownByPlayerId',
        parameter: 'mapObjectives',
        type: 'Iterable<MapObjectiveDefinition>',
      ),
    ],
  ),
  _Target(
    path:
        'lib/game/domain/reducer/game_state/'
        'game_state_reducer.dart',
    owner: 'GameStateReducer',
    boundaries: [
      _Boundary.constructor('', parameter: 'mapData', type: 'MapReadView'),
    ],
  ),
  _Target(
    path:
        'lib/game/domain/reducer/game_state/'
        'reducer_environment.dart',
    owner: 'ReducerEnvironment',
    boundaries: [
      _Boundary.constructor('', parameter: 'mapData', type: 'MapReadView'),
      _Boundary.method(
        'copyWith',
        parameter: 'mapData',
        type: 'MapReadView',
        nullable: true,
      ),
    ],
  ),
  _Target(
    path:
        'packages/aonw_core/lib/game/domain/trade/'
        'resource_trade_command_resolver.dart',
    owner: 'ResourceTradeCommandResolver',
    boundaries: [
      _Boundary.method(
        'openGoldForResourceTrade',
        parameter: 'mapTiles',
        type: 'MapTileLookup',
      ),
      _Boundary.method(
        'openResourceForResourceTrade',
        parameter: 'mapTiles',
        type: 'MapTileLookup',
      ),
    ],
  ),
  _Target(
    path:
        'packages/aonw_core/lib/game/domain/trade/'
        'persistent_resource_trade_resolver.dart',
    owner: 'PersistentResourceTradeResolver',
    boundaries: [
      _Boundary.method(
        'openGoldForResourceTrade',
        parameter: 'mapTiles',
        type: 'MapTileLookup',
      ),
      _Boundary.method(
        'openResourceForResourceTrade',
        parameter: 'mapTiles',
        type: 'MapTileLookup',
      ),
    ],
  ),
  _Target(
    path:
        'packages/aonw_core/lib/game/domain/trade/'
        'domain_resource_trade_command_resolver.dart',
    owner: 'DomainResourceTradeCommandResolver',
    boundaries: [
      _Boundary.method(
        'openGoldForResourceTrade',
        parameter: 'mapTiles',
        type: 'MapTileLookup',
      ),
      _Boundary.method(
        'openResourceForResourceTrade',
        parameter: 'mapTiles',
        type: 'MapTileLookup',
      ),
    ],
  ),
  _Target(
    path: 'lib/game/domain/reducer/diplomacy/resource_trade_reducer.dart',
    owner: 'ResourceTradeReducer',
    boundaries: [
      _Boundary.method(
        'openTrade',
        parameter: 'mapTiles',
        type: 'MapTileLookup',
      ),
      _Boundary.method(
        'openExchange',
        parameter: 'mapTiles',
        type: 'MapTileLookup',
      ),
    ],
  ),
  _Target(
    path:
        'lib/game/domain/reducer/diplomacy/'
        'merchant_trade_route_reducer.dart',
    owner: 'MerchantTradeRouteReducer',
    boundaries: [
      _Boundary.method(
        'startSelection',
        parameter: 'mapView',
        type: 'MapTraversalView',
      ),
      _Boundary.method(
        'assignRoute',
        parameter: 'mapView',
        type: 'MapTraversalView',
      ),
      _Boundary.method(
        'startMoveToCitySelection',
        parameter: 'mapView',
        type: 'MapTraversalView',
      ),
      _Boundary.method(
        'moveToCity',
        parameter: 'mapView',
        type: 'MapTraversalView',
      ),
      _Boundary.method(
        '_unitSelection',
        parameter: 'mapTiles',
        type: 'MapTileLookup',
      ),
    ],
  ),
  _Target(
    path: 'lib/game/domain/reducer/research/research_reducer.dart',
    owner: 'ResearchReducer',
    boundaries: [
      _Boundary.method(
        'selectTechnology',
        parameter: 'mapTiles',
        type: 'MapTileLookup',
      ),
    ],
  ),
  _Target(
    path:
        'packages/aonw_core/lib/game/domain/technology/persistent_research_command_resolver.dart',
    owner: 'PersistentResearchCommandResolver',
    boundaries: [
      _Boundary.method(
        'selectTechnology',
        parameter: 'mapTiles',
        type: 'MapTileLookup',
        nullable: true,
      ),
    ],
  ),
  _Target(
    path:
        'packages/aonw_core/lib/game/domain/technology/domain_research_command_resolver.dart',
    owner: 'DomainResearchCommandResolver',
    boundaries: [
      _Boundary.method(
        'selectTechnology',
        parameter: 'mapTiles',
        type: 'MapTileLookup',
        nullable: true,
      ),
    ],
  ),
  _Target(
    path:
        'packages/aonw_core/lib/game/domain/technology/select_technology_resolver.dart',
    owner: 'SelectTechnologyResolver',
    boundaries: [
      _Boundary.method(
        'selectTechnology',
        parameter: 'mapTiles',
        type: 'MapTileLookup',
        nullable: true,
      ),
    ],
  ),
];
