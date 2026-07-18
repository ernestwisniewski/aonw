import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/map_boundary_source_guard.dart';

part 'support/economy_simulation_map_view_guard.dart';
part 'support/economy_simulation_map_view_fixtures.dart';
part 'support/local_reducer_map_view_guard.dart';
part 'support/local_reducer_map_view_fixtures.dart';
part 'support/server_map_cache_boundary_guard.dart';
part 'support/server_map_cache_flow_guard.dart';
part 'support/server_map_cache_boundary_fixtures.dart';
part 'support/world_map_read_view_boundary_fixtures.dart';
part 'support/world_map_read_view_boundary_guard.dart';

const _coreLib = 'packages/aonw_core/lib';
const _gameDomain = '$_coreLib/game/domain';
const _legacyWorldMapAdapterPath =
    '$_coreLib/map/persistence/legacy_world_map_adapter.dart';
const _mapDataBarrelFreeMigrationPaths = {
  'lib/game/domain/hex_assessment/hex_assessment_rules.dart',
  'lib/game/application/services/ai_turn_preparation_builder.dart',
  'lib/game/application/use_cases/run_ai_turn_use_case.dart',
  'lib/game/domain/ai/pressure_target_resolver.dart',
  'lib/game/domain/city_selection_projector.dart',
  'lib/game/domain/game_selection.dart',
  'lib/game/domain/movement/unit_movement_planner.dart',
  'lib/game/domain/movement/unit_movement_turn_rules.dart',
  'lib/game/domain/reducer/movement/movement_reducer.dart',
  'lib/game/domain/reducer/movement/movement_reducer_auto_explore.dart',
  'lib/game/domain/reducer/movement/movement_reducer_direct_move.dart',
  'lib/game/domain/reducer/movement/movement_reducer_move_preview.dart',
  'lib/game/domain/reducer/movement/movement_reducer_turn_reset.dart',
  'lib/game/domain/reducer/movement/movement_reducer_unit_action_state.dart',
  'lib/game/domain/reducer/city/city_expansion_reducer.dart',
  'lib/game/domain/reducer/city/city_founding_reducer.dart',
  'lib/game/domain/reducer/city/city_production_reducer.dart',
  'lib/game/domain/reducer/city/city_production_reducer_building.dart',
  'lib/game/domain/reducer/city/city_production_reducer_project.dart',
  'lib/game/domain/reducer/city/city_production_reducer_rush.dart',
  'lib/game/domain/reducer/city/city_production_reducer_specialization.dart',
  'lib/game/domain/reducer/city/city_production_reducer_unit.dart',
  'lib/game/domain/reducer/city/city_production_reducer_wonder.dart',
  'lib/game/domain/reducer/city/city_worked_hex_reducer.dart',
  'lib/game/domain/reducer/game_state/game_state_reducer.dart',
  'lib/game/domain/reducer/game_state/game_state_reducer_active_player.dart',
  'lib/game/domain/reducer/game_state/'
      'game_state_reducer_interaction_state.dart',
  'lib/game/domain/reducer/game_state/game_state_reducer_taps.dart',
  'lib/game/domain/reducer/game_state/reducer_environment.dart',
  'lib/game/domain/reducer/game_state/reducer_environment_dispatch.dart',
  'lib/game/domain/reducer/game_state/'
      'reducer_environment_interaction_dispatch.dart',
  'lib/game/domain/reducer/combat/combat_reducer.dart',
  'lib/game/domain/reducer/combat/combat_reducer_fog.dart',
  'lib/game/domain/reducer/combat/combat_reducer_setup.dart',
  'lib/game/domain/reducer/diplomacy/merchant_trade_route_reducer.dart',
  'lib/game/domain/reducer/diplomacy/resource_trade_reducer.dart',
  'lib/game/domain/reducer/interaction/selection_reducer.dart',
  'lib/game/domain/reducer/research/research_reducer.dart',
  'lib/game/domain/reducer/turn/end_turn_reducer.dart',
  'lib/game/domain/reducer/turn/turn_reducer.dart',
  'lib/game/domain/reducer/unit/unit_attachment_reducer.dart',
  'lib/game/domain/reducer/worker/worker_reducer.dart',
  'lib/game/domain/turn/phases/selection_refresh_phase.dart',
  'lib/game/domain/turn/turn_context.dart',
  'lib/game/presentation/engine/game_hover_intent_resolver.dart',
  'lib/game/presentation/services/ai_turn_process_preparer.dart',
  'lib/game/presentation/widgets/hud/city/'
      'hud_city_founding_availability.dart',
  'lib/game/presentation/widgets/hud/turn/turn_action_hint.dart',
  'lib/game/presentation/widgets/selection/view_models/'
      'selection_resource_value_card_factory.dart',
  'lib/game/presentation/widgets/selection/view_models/'
      'selection_value_formatters.dart',
  'lib/game/presentation/widgets/selection/view_models/'
      'tile_selection_view_model_factory.dart',
  '$_gameDomain/city/city_initial_territory_selector.dart',
  '$_gameDomain/outcome/score_race_analyzer.dart',
  '$_gameDomain/trade/persistent_resource_trade_resolver.dart',
};
const _mapDataFreeMigrationPaths = {
  ..._mapDataBarrelFreeMigrationPaths,
  '$_gameDomain/city/persistent_city_expansion_resolver.dart',
  '$_gameDomain/city/city_expansion_command_resolver.dart',
  '$_gameDomain/city/domain_city_expansion_resolver.dart',
  '$_gameDomain/city/persistent_city_founding_resolver.dart',
  '$_gameDomain/city/persistent_city_production_resolver.dart',
  '$_gameDomain/city/city_production_command_resolver.dart',
  '$_gameDomain/city/rush_production_command_resolver.dart',
  '$_gameDomain/city/rush_production_command_completion.dart',
  '$_gameDomain/city/rush_production_command_economy.dart',
  '$_gameDomain/city/domain_city_production_resolver.dart',
  '$_gameDomain/city/city_turn_processor.dart',
  '$_gameDomain/city/persistent_worker_command_resolver.dart',
  '$_gameDomain/city/worker_command_resolver.dart',
  '$_gameDomain/city/domain_worker_command_resolver.dart',
  '$_gameDomain/combat/persistent_combat_command_resolver.dart',
  '$_gameDomain/fog/fog_of_war_service.dart',
  '$_gameDomain/fog/fog_reveal_calculator.dart',
  '$_gameDomain/movement/unit_movement_cost_rules.dart',
  '$_gameDomain/movement/persistent_move_unit_resolver.dart',
  '$_gameDomain/movement/persistent_merchant_trade_route_resolver.dart',
  '$_gameDomain/movement/persistent_unit_action_resolver.dart',
  '$_gameDomain/movement/merchant_trade_route_rules.dart',
  '$_gameDomain/movement/scout_auto_explore_planner.dart',
  '$_gameDomain/movement/unit_movement_pathfinder.dart',
  '$_gameDomain/outcome/domination_progress_calculator.dart',
  '$_gameDomain/outcome/game_outcome_detector.dart',
  '$_gameDomain/stability/persistent_stability_processor.dart',
  '$_gameDomain/stability/stability_input_builder.dart',
  '$_gameDomain/technology/domain_research_command_resolver.dart',
  '$_gameDomain/technology/persistent_research_command_resolver.dart',
  '$_gameDomain/technology/research_turn_processor.dart',
  '$_gameDomain/technology/select_technology_resolver.dart',
  '$_gameDomain/technology/strategic_resource_discovery_rules.dart',
  '$_gameDomain/terrain/tile_terrain_profile_rules.dart',
  '$_gameDomain/turn/persistent_turn_combat_resolver.dart',
  '$_gameDomain/turn/persistent_turn_economy_processor.dart',
  '$_gameDomain/turn/persistent_turn_movement_processor.dart',
  '$_gameDomain/turn/persistent_turn_pipeline.dart',
  '$_gameDomain/unit/detach_troop_resolver.dart',
  '$_gameDomain/unit/domain_unit_detachment_resolver.dart',
  '$_gameDomain/unit/persistent_unit_detachment_resolver.dart',
  '$_gameDomain/unit/starting_units.dart',
  '$_gameDomain/unit/unit_fortification_rules.dart',
  '$_gameDomain/unit/worker_turn_processor.dart',
  '$_coreLib/ai/simulation/economy_simulation_command_applier.dart',
  '$_coreLib/ai/simulation/economy_simulation_command_applier_production.dart',
  '$_coreLib/ai/simulation/economy_simulation_turn_row_factory.dart',
};

void main() {
  test('legacy world-map adapter remains removed from production', () {
    expect(File(_legacyWorldMapAdapterPath).existsSync(), isFalse);
    expect(
      removedProductionSymbolViolations(
        productionDartSources(),
        symbol: 'LegacyWorldMapAdapter',
        uriSuffix: '/legacy_world_map_adapter.dart',
      ),
      isEmpty,
    );
  });

  test('MCTS production depends only on canonical map read contracts', () {
    final mctsSources = productionDartSources().entries.where(
      (entry) => entry.key.startsWith('$_coreLib/ai/mcts/'),
    );
    for (final entry in mctsSources) {
      expect(
        sourceSymbolReferenceViolations(
          entry.value,
          entry.key,
          symbol: 'MapData',
        ),
        isEmpty,
        reason: entry.key,
      );
      expect(
        sourceSymbolReferenceViolations(
          entry.value,
          entry.key,
          symbol: 'WorldMap',
        ),
        isEmpty,
        reason: entry.key,
      );
    }
  });

  test('economy simulation owns one shared indexed map view', () {
    expect(_economySimulationMapViewViolations(), isEmpty);
  });

  test('server map cache owns one validated indexed map view', () {
    expect(_serverMapCacheBoundaryViolations(), isEmpty);
  });

  test('local reducer composition roots own one indexed map view', () {
    expect(_localReducerMapViewViolations(), isEmpty);
  });

  test('migrated map paths do not reference MapData', () {
    for (final path in _mapDataFreeMigrationPaths) {
      expect(
        sourceSymbolReferenceViolations(
          File(path).readAsStringSync(),
          path,
          symbol: 'MapData',
        ),
        isEmpty,
        reason: path,
      );
    }
  });

  test('migrated map views do not import the legacy map DTO barrel', () {
    for (final path in _mapDataBarrelFreeMigrationPaths) {
      expect(
        removedProductionSymbolViolations(
          {path: File(path).readAsStringSync()},
          symbol: 'MapData',
          uriSuffix: '/map_data.dart',
        ),
        isEmpty,
        reason: path,
      );
    }
  });

  test('migrated bounded rules do not depend on persistence tile DTOs', () {
    for (final path in _mapTileViewMigrationPaths) {
      expect(
        sourceSymbolReferenceViolations(
          File(path).readAsStringSync(),
          path,
          symbol: 'TileData',
        ),
        isEmpty,
        reason: path,
      );
    }
  });

  test('game presentation does not reconstruct persistence tile DTOs', () {
    final sources = Map.fromEntries(
      productionDartSources(containing: 'TileData').entries.where(
        (entry) => entry.key.startsWith('lib/game/presentation/'),
      ),
    );
    expect(constructedTypeViolations(sources, type: 'TileData'), isEmpty);
  });

  test('constructed type guard matches only the exact DTO name', () {
    expect(
      constructedTypeViolations(const {
        'fixture.dart': '''
void buildTiles() {
  TileData();
  TileData.named();
  dto.TileData.named();
  MultiplayerAvatarTileData();
}
''',
      }, type: 'TileData'),
      [
        'fixture.dart:2 must not construct TileData',
        'fixture.dart:3 must not construct TileData',
        'fixture.dart:4 must not construct TileData',
      ],
    );
  });

  test('read contracts and WorldMap view remain zero-copy', () {
    expect(
      _mapTileLookupContractViolations(
        File(_mapReadViewPath).readAsStringSync(),
        _mapReadViewPath,
      ),
      isEmpty,
    );
    expect(
      _worldMapReadViewViolations(
        File(_worldMapReadViewPath).readAsStringSync(),
        _worldMapReadViewPath,
      ),
      isEmpty,
    );
  });

  _registerEconomySimulationMapViewFixtures();
  _registerServerMapCacheBoundaryFixtures();
  _registerWorldMapReadViewBoundaryFixtures();
  _registerLocalReducerMapViewFixtures();
}
