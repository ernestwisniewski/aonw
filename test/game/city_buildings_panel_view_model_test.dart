import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/presentation/widgets/bottom_toolbar/view_models.dart';
import 'package:aonw/l10n/generated/app_localizations_en.dart';
import 'package:aonw/map/domain/map_data.dart';
import 'package:aonw/map/domain/terrain_type.dart';
import 'package:aonw_core/game/domain/match_rules.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CityBuildingsPanelViewModelFactory', () {
    final l10n = AppLocalizationsEn();
    const city = GameCity(
      id: 'city_1',
      ownerPlayerId: 'player_1',
      name: 'City',
      center: CityHex(col: 1, row: 1),
    );

    ResearchState researchWith(Set<TechnologyId> unlocked) {
      return ResearchState(
        players: {
          'player_1': PlayerResearchState(unlockedTechnologyIds: unlocked),
        },
      );
    }

    CityBuildingCardViewModel card(
      CityBuildingsPanelViewModel viewModel,
      CityBuildingType type,
    ) {
      return viewModel.buildings.firstWhere(
        (building) => building.type == type,
      );
    }

    MapData mapWithCenterTerrain(TerrainType terrain) {
      return MapData(
        cols: 3,
        rows: 3,
        tiles: [
          for (int row = 0; row < 3; row++)
            for (int col = 0; col < 3; col++)
              TileData(
                col: col,
                row: row,
                terrains: [
                  col == 1 && row == 1 ? terrain : TerrainType.grassland,
                ],
                resources: const [],
                height: 0,
              ),
        ],
      );
    }

    MapData mapWithCenterResource(ResourceType resource) {
      return MapData(
        cols: 3,
        rows: 3,
        tiles: [
          for (int row = 0; row < 3; row++)
            for (int col = 0; col < 3; col++)
              TileData(
                col: col,
                row: row,
                terrains: const [TerrainType.grassland],
                resources: col == 1 && row == 1 ? [resource] : const [],
                height: 0,
              ),
        ],
      );
    }

    final customCityRuleset = CityRulesets.standard.copyWith(
      buildings: {
        ...CityRulesets.standard.buildings,
        CityBuildingType.granary: const CityBuildingDefinition(
          type: CityBuildingType.granary,
          productionCost: 7,
        ),
        CityBuildingType.waterMill: const CityBuildingDefinition(
          type: CityBuildingType.waterMill,
          productionCost: 4,
        ),
        CityBuildingType.workshop: const CityBuildingDefinition(
          type: CityBuildingType.workshop,
          productionCost: 4,
        ),
        CityBuildingType.storehouse: const CityBuildingDefinition(
          type: CityBuildingType.storehouse,
          productionCost: 3,
        ),
        CityBuildingType.housing: const CityBuildingDefinition(
          type: CityBuildingType.housing,
          productionCost: 5,
        ),
      },
    );

    test('shows base building as available without research', () {
      final viewModel = CityBuildingsPanelViewModelFactory.from(
        city,
        l10n: l10n,
      );

      expect(
        card(viewModel, CityBuildingType.granary).state,
        CityBuildingCardState.available,
      );
    });

    test('marks technology buildings as locked without research', () {
      final viewModel = CityBuildingsPanelViewModelFactory.from(
        city,
        l10n: l10n,
      );
      final workshop = card(viewModel, CityBuildingType.workshop);

      expect(workshop.state, CityBuildingCardState.locked);
      expect(workshop.requirementLabel, 'Requires: Craftsmanship');
    });

    test('marks researched technology buildings as available', () {
      final viewModel = CityBuildingsPanelViewModelFactory.from(
        city,
        l10n: l10n,
        research: researchWith({TechnologyId.craftsmanship}),
      );

      expect(
        card(viewModel, CityBuildingType.workshop).state,
        CityBuildingCardState.available,
      );
    });

    test('locks coastal buildings without coastal access', () {
      final viewModel = CityBuildingsPanelViewModelFactory.from(
        city,
        l10n: l10n,
        research: researchWith({TechnologyId.navigation}),
        mapData: mapWithCenterTerrain(TerrainType.grassland),
      );
      final port = card(viewModel, CityBuildingType.port);

      expect(port.state, CityBuildingCardState.locked);
      expect(port.requirementLabel, 'Requires: coastal access');
    });

    test('allows coastal buildings with coastal access', () {
      final viewModel = CityBuildingsPanelViewModelFactory.from(
        city,
        l10n: l10n,
        research: researchWith({TechnologyId.navigation}),
        mapData: mapWithCenterTerrain(TerrainType.coast),
      );

      expect(
        card(viewModel, CityBuildingType.port).state,
        CityBuildingCardState.available,
      );
    });

    test('locks resource buildings with resource label', () {
      final lockedViewModel = CityBuildingsPanelViewModelFactory.from(
        city,
        l10n: l10n,
        research: researchWith({
          TechnologyId.animalHusbandry,
          TechnologyId.horsebackRiding,
        }),
        mapData: mapWithCenterTerrain(TerrainType.grassland),
      );
      final unlockedViewModel = CityBuildingsPanelViewModelFactory.from(
        city,
        l10n: l10n,
        research: researchWith({
          TechnologyId.animalHusbandry,
          TechnologyId.horsebackRiding,
        }),
        mapData: mapWithCenterResource(ResourceType.horses),
      );

      final lockedStable = card(lockedViewModel, CityBuildingType.stable);
      expect(lockedStable.state, CityBuildingCardState.locked);
      expect(lockedStable.requirementLabel, 'Requires: horses');
      expect(
        card(unlockedViewModel, CityBuildingType.stable).state,
        CityBuildingCardState.available,
      );
    });

    test(
      'uses new branch technology names in locked building requirements',
      () {
        final viewModel = CityBuildingsPanelViewModelFactory.from(
          city,
          l10n: l10n,
        );
        final buildersGuild = card(viewModel, CityBuildingType.buildersGuild);

        expect(buildersGuild.state, CityBuildingCardState.locked);
        expect(buildersGuild.requirementLabel, 'Requires: Engineering');
      },
    );

    test('uses city ruleset production cost for card costs', () {
      final viewModel = CityBuildingsPanelViewModelFactory.from(
        city,
        l10n: l10n,
        cityRuleset: customCityRuleset,
        paceBalance: PaceBalance.long120,
      );

      expect(card(viewModel, CityBuildingType.granary).totalCost, 7);
    });

    test('estimates remaining turns from city production per turn', () {
      final viewModel = CityBuildingsPanelViewModelFactory.from(
        city.copyWith(
          productionQueue: CityProductionQueue.building(
            buildingType: CityBuildingType.granary,
            investedProduction: 1,
          ),
        ),
        l10n: l10n,
        cityRuleset: customCityRuleset,
        paceBalance: PaceBalance.long120,
        productionPerTurn: 2,
      );

      final granary = card(viewModel, CityBuildingType.granary);
      expect(granary.investedProduction, 1);
      expect(granary.totalCost, 7);
      expect(granary.productionPerTurn, 2);
      expect(granary.turnsRemaining, 3);
    });
  });
}
