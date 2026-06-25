import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/presentation/widgets/city/city_production_dialog_view_model.dart';
import 'package:aonw/l10n/generated/app_localizations_en.dart';
import 'package:aonw/map/domain/map_data.dart';
import 'package:aonw/map/domain/terrain_type.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/trade.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final l10n = AppLocalizationsEn();

  test(
    'CityProductionDialogViewModel groups available and future production',
    () {
      const city = GameCity(
        id: 'city_1',
        ownerPlayerId: 'player_1',
        name: 'Krakow',
        center: CityHex(col: 1, row: 1),
      );

      final viewModel = CityProductionDialogViewModel.from(
        city,
        l10n: l10n,
        cityRuleset: CityRulesets.standard,
        research: ResearchState.empty,
        technologyRuleset: TechnologyRulesets.standard,
        mapData: null,
        cities: const [],
        units: const [],
        fieldImprovements: const [],
        productionPerTurn: 2,
      );

      expect(viewModel.cityName, 'Krakow');
      expect(viewModel.productionPerTurn, 2);
      expect(viewModel.hasItems, isTrue);
      expect(
        viewModel.buildings.map((item) => item.title),
        contains('Granary'),
      );
      expect(
        viewModel.futureBuildings.map((item) => item.title),
        contains('Workshop'),
      );
      expect(viewModel.units.map((item) => item.title), contains('Warrior'));
      expect(
        viewModel.projects.map((item) => item.title),
        contains('Research'),
      );
      expect(viewModel.specializations, isEmpty);
    },
  );

  test(
    'CityProductionDialogViewModel exposes active item and specialization',
    () {
      final city = GameCity(
        id: 'city_1',
        ownerPlayerId: 'player_1',
        name: 'Miasto',
        center: const CityHex(col: 1, row: 1),
        productionQueue: CityProductionQueue.unit(
          unitType: GameUnitType.warrior,
          investedProduction: 6,
        ),
        specialization: CitySpecializationType.science,
      );
      final research = ResearchState(
        players: {
          'player_1': PlayerResearchState(
            unlockedTechnologyIds: {TechnologyId.specialization},
          ),
        },
      );

      final viewModel = CityProductionDialogViewModel.from(
        city,
        l10n: l10n,
        cityRuleset: CityRulesets.standard,
        research: research,
        technologyRuleset: TechnologyRulesets.standard,
        mapData: null,
        cities: const [],
        units: const [],
        fieldImprovements: const [],
        productionPerTurn: 4,
        currentTurn: 5,
      );

      expect(viewModel.activeItem?.unitType, GameUnitType.warrior);
      expect(
        viewModel.activeItem?.effectiveEta.compactLabel(l10n),
        '4 turns • T9',
      );
      expect(viewModel.itemForUnit(GameUnitType.warrior)?.active, isTrue);
      expect(
        viewModel.specializations
            .singleWhere((item) => item.type == CitySpecializationType.science)
            .active,
        isTrue,
      );
    },
  );

  test(
    'CityProductionDialogViewModel locks specializations without anchor building',
    () {
      const city = GameCity(
        id: 'city_1',
        ownerPlayerId: 'player_1',
        name: 'Miasto',
        center: CityHex(col: 1, row: 1),
        buildings: {CityBuildingType.granary},
      );
      final research = ResearchState(
        players: {
          'player_1': PlayerResearchState(
            unlockedTechnologyIds: {TechnologyId.specialization},
          ),
        },
      );

      final viewModel = CityProductionDialogViewModel.from(
        city,
        l10n: l10n,
        cityRuleset: CityRulesets.standard,
        research: research,
        technologyRuleset: TechnologyRulesets.standard,
        mapData: null,
        cities: const [],
        units: const [],
        fieldImprovements: const [],
        productionPerTurn: 4,
      );

      final growth = viewModel.specializations.singleWhere(
        (item) => item.type == CitySpecializationType.growth,
      );
      final science = viewModel.specializations.singleWhere(
        (item) => item.type == CitySpecializationType.science,
      );

      expect(growth.locked, isFalse);
      expect(science.locked, isTrue);
      expect(science.metaLabels, contains('Requires: Archive'));
    },
  );

  test(
    'CityProductionDialogViewModel marks best fitting city specialization',
    () {
      const city = GameCity(
        id: 'city_1',
        ownerPlayerId: 'player_1',
        name: 'Port',
        center: CityHex(col: 0, row: 0),
        buildings: {
          CityBuildingType.granary,
          CityBuildingType.workshop,
          CityBuildingType.merchantHall,
          CityBuildingType.archive,
          CityBuildingType.barracks,
        },
      );
      final research = ResearchState(
        players: {
          'player_1': PlayerResearchState(
            unlockedTechnologyIds: {TechnologyId.specialization},
          ),
        },
      );

      final viewModel = CityProductionDialogViewModel.from(
        city,
        l10n: l10n,
        cityRuleset: CityRulesets.standard,
        research: research,
        technologyRuleset: TechnologyRulesets.standard,
        mapData: MapData(
          cols: 1,
          rows: 1,
          tiles: const [
            TileData(
              col: 0,
              row: 0,
              terrains: [TerrainType.coast],
              resources: [],
              height: 0,
            ),
          ],
        ),
        cities: const [city],
        units: const [],
        fieldImprovements: const [],
        productionPerTurn: 4,
      );

      final commerce = viewModel.specializations.singleWhere(
        (item) => item.type == CitySpecializationType.commerce,
      );
      final industry = viewModel.specializations.singleWhere(
        (item) => item.type == CitySpecializationType.industry,
      );

      expect(commerce.bestFit, isTrue);
      expect(commerce.metaLabels, contains('Best fit'));
      expect(industry.bestFit, isFalse);
      expect(industry.metaLabels, isNot(contains('Best fit')));
    },
  );

  test('CityProductionDialogViewModel labels next worker upkeep', () {
    const city = GameCity(
      id: 'city_1',
      ownerPlayerId: 'player_1',
      name: 'Miasto',
      center: CityHex(col: 1, row: 1),
    );
    final workers = [
      for (var i = 0; i < 5; i++)
        GameUnit(
          id: 'worker_$i',
          ownerPlayerId: 'player_1',
          type: GameUnitType.worker,
          name: GameUnitType.worker.defaultNameToken,
          col: i,
          row: 0,
        ),
    ];

    final viewModel = CityProductionDialogViewModel.from(
      city,
      l10n: l10n,
      cityRuleset: CityRulesets.standard,
      research: ResearchState.empty,
      technologyRuleset: TechnologyRulesets.standard,
      mapData: null,
      cities: const [city],
      units: workers,
      fieldImprovements: const [],
      productionPerTurn: 4,
    );

    expect(
      viewModel.itemForUnit(GameUnitType.worker)?.metaLabels,
      contains('next upkeep: 2'),
    );
  });

  test('CityProductionDialogViewModel uses map-scaled unit supply limit', () {
    final cities = [
      for (var i = 0; i < 5; i++)
        GameCity(
          id: 'city_$i',
          ownerPlayerId: 'player_1',
          name: 'Miasto $i',
          population: 3,
          center: const CityHex(col: 1, row: 1),
          controlledHexes: const [
            CityHex(col: 1, row: 0),
            CityHex(col: 0, row: 1),
          ],
        ),
    ];
    final units = [
      for (var i = 0; i < CityUnitSupplyRules.minimumMapCapacity; i++)
        GameUnit(
          id: 'warrior_$i',
          ownerPlayerId: 'player_1',
          type: GameUnitType.warrior,
          name: GameUnitType.warrior.defaultNameToken,
          col: i % 3,
          row: i ~/ 3,
        ),
    ];

    final viewModel = CityProductionDialogViewModel.from(
      cities.first,
      l10n: l10n,
      cityRuleset: CityRulesets.standard,
      research: ResearchState.empty,
      technologyRuleset: TechnologyRulesets.standard,
      mapData: _map3x3(),
      cities: cities,
      units: units,
      fieldImprovements: const [],
      productionPerTurn: 4,
    );

    final warrior = viewModel.itemForUnit(GameUnitType.warrior);

    expect(warrior, isNotNull);
    expect(warrior!.locked, isTrue);
    expect(
      warrior.requirementLabel,
      l10n.cityProductionUnitSupplyLimit(
        CityUnitSupplyRules.minimumMapCapacity,
        CityUnitSupplyRules.minimumMapCapacity,
      ),
    );
    expect(
      warrior.metaLabels,
      contains(
        l10n.cityProductionUnitSupplyUsed(
          CityUnitSupplyRules.minimumMapCapacity,
          CityUnitSupplyRules.minimumMapCapacity,
        ),
      ),
    );
  });

  test(
    'CityProductionDialogViewModel locks unit without required resource',
    () {
      const city = GameCity(
        id: 'city_1',
        ownerPlayerId: 'player_1',
        name: 'Miasto',
        center: CityHex(col: 1, row: 1),
      );
      final research = ResearchState(
        players: {
          'player_1': PlayerResearchState(
            unlockedTechnologyIds: {TechnologyId.horsebackRiding},
          ),
        },
      );

      final viewModel = CityProductionDialogViewModel.from(
        city,
        l10n: l10n,
        cityRuleset: CityRulesets.standard,
        research: research,
        technologyRuleset: TechnologyRulesets.standard,
        mapData: _map3x3(),
        cities: const [city],
        units: const [],
        fieldImprovements: const [],
        productionPerTurn: 4,
      );

      final cavalry = viewModel.itemForUnit(GameUnitType.cavalry);

      expect(cavalry, isNotNull);
      expect(cavalry!.locked, isTrue);
      expect(cavalry.requirementLabel, 'Requires: horses');
    },
  );

  test(
    'CityProductionDialogViewModel unlocks resource unit with imported resource',
    () {
      const city = GameCity(
        id: 'city_1',
        ownerPlayerId: 'player_1',
        name: 'Miasto',
        center: CityHex(col: 1, row: 1),
      );
      final research = ResearchState(
        players: {
          'player_1': PlayerResearchState(
            unlockedTechnologyIds: {TechnologyId.horsebackRiding},
          ),
        },
      );

      final viewModel = CityProductionDialogViewModel.from(
        city,
        l10n: l10n,
        cityRuleset: CityRulesets.standard,
        research: research,
        technologyRuleset: TechnologyRulesets.standard,
        mapData: _map3x3(),
        cities: const [city],
        units: const [],
        fieldImprovements: const [],
        resourceTradeAgreements: const [
          ResourceTradeAgreement(
            id: 'trade_horses',
            exporterPlayerId: 'player_2',
            importerPlayerId: 'player_1',
            resource: ResourceType.horses,
            goldPerTurn: 3,
            remainingTurns: 8,
          ),
        ],
        productionPerTurn: 4,
      );

      final cavalry = viewModel.itemForUnit(GameUnitType.cavalry);

      expect(cavalry, isNotNull);
      expect(cavalry!.locked, isFalse);
      expect(cavalry.requirementLabel, isNull);
    },
  );

  test('CityProductionDialogViewModel unlocks merchant after trade', () {
    const city = GameCity(
      id: 'city_1',
      ownerPlayerId: 'player_1',
      name: 'Miasto',
      center: CityHex(col: 1, row: 1),
    );
    final tradeResearch = ResearchState(
      players: {
        'player_1': PlayerResearchState(
          unlockedTechnologyIds: {TechnologyId.trade},
        ),
      },
    );

    final lockedViewModel = CityProductionDialogViewModel.from(
      city,
      l10n: l10n,
      cityRuleset: CityRulesets.standard,
      research: ResearchState.empty,
      technologyRuleset: TechnologyRulesets.standard,
      mapData: null,
      cities: const [city],
      units: const [],
      fieldImprovements: const [],
      productionPerTurn: 4,
    );
    final unlockedViewModel = CityProductionDialogViewModel.from(
      city,
      l10n: l10n,
      cityRuleset: CityRulesets.standard,
      research: tradeResearch,
      technologyRuleset: TechnologyRulesets.standard,
      mapData: null,
      cities: const [city],
      units: const [],
      fieldImprovements: const [],
      productionPerTurn: 4,
    );

    expect(lockedViewModel.itemForUnit(GameUnitType.merchant), isNull);
    expect(unlockedViewModel.itemForUnit(GameUnitType.merchant), isNotNull);
  });

  test('CityProductionDialogViewModel applies project specialization pace', () {
    const city = GameCity(
      id: 'city_1',
      ownerPlayerId: 'player_1',
      name: 'Miasto',
      center: CityHex(col: 1, row: 1),
      specialization: CitySpecializationType.science,
    );

    final viewModel = CityProductionDialogViewModel.from(
      city,
      l10n: l10n,
      cityRuleset: CityRulesets.standard,
      research: ResearchState.empty,
      technologyRuleset: TechnologyRulesets.standard,
      mapData: null,
      cities: const [city],
      units: const [],
      fieldImprovements: const [],
      productionPerTurn: 4,
    );

    final researchProject = viewModel.projects.singleWhere(
      (project) => project.projectType == CityProjectType.research,
    );

    expect(researchProject.productionPerTurn, 5);
    expect(
      researchProject.metaLabels,
      contains(l10n.cityProjectSciencePerTurn(1)),
    );
  });

  test('CityProductionDialogViewModel locks naval units without coast', () {
    const city = GameCity(
      id: 'city_1',
      ownerPlayerId: 'player_1',
      name: 'Miasto',
      center: CityHex(col: 1, row: 1),
    );
    final research = ResearchState(
      players: {
        'player_1': PlayerResearchState(
          unlockedTechnologyIds: {TechnologyId.cartography},
        ),
      },
    );

    final inlandViewModel = CityProductionDialogViewModel.from(
      city,
      l10n: l10n,
      cityRuleset: CityRulesets.standard,
      research: research,
      technologyRuleset: TechnologyRulesets.standard,
      mapData: _map3x3(),
      cities: const [city],
      units: const [],
      fieldImprovements: const [],
      productionPerTurn: 4,
    );
    final coastalViewModel = CityProductionDialogViewModel.from(
      city,
      l10n: l10n,
      cityRuleset: CityRulesets.standard,
      research: research,
      technologyRuleset: TechnologyRulesets.standard,
      mapData: _map3x3(coast: (col: 2, row: 1), ocean: (col: 2, row: 2)),
      cities: const [city],
      units: const [],
      fieldImprovements: const [],
      productionPerTurn: 4,
    );

    final inlandScoutShip = inlandViewModel.itemForUnit(GameUnitType.scoutShip);
    final coastalScoutShip = coastalViewModel.itemForUnit(
      GameUnitType.scoutShip,
    );

    expect(inlandScoutShip, isNotNull);
    expect(inlandScoutShip!.locked, isTrue);
    expect(inlandScoutShip.requirementLabel, l10n.requirementCoastalAccess);
    expect(coastalScoutShip, isNotNull);
    expect(coastalScoutShip!.locked, isFalse);
    expect(coastalScoutShip.requirementLabel, isNull);
  });

  test('CityProductionDialogViewModel exposes current yield for details', () {
    const city = GameCity(
      id: 'city_1',
      ownerPlayerId: 'player_1',
      name: 'Miasto',
      population: 1,
      center: CityHex(col: 0, row: 0),
      controlledHexes: [CityHex(col: 1, row: 0)],
    );

    final viewModel = CityProductionDialogViewModel.from(
      city,
      l10n: l10n,
      cityRuleset: CityRulesets.standard,
      research: ResearchState.empty,
      technologyRuleset: TechnologyRulesets.standard,
      mapData: _map(),
      cities: const [city],
      units: const [],
      fieldImprovements: const [],
      productionPerTurn: 0,
    );

    expect(viewModel.currentCityYield, isNotNull);
    expect(viewModel.currentCityYield!.food, greaterThanOrEqualTo(0));
    expect(viewModel.currentCityYield!.production, greaterThan(0));
    expect(viewModel.currentCityScience, greaterThanOrEqualTo(0));
  });

  test('CityProductionDialogViewModel exposes building sort metrics', () {
    const city = GameCity(
      id: 'city_1',
      ownerPlayerId: 'player_1',
      name: 'Miasto',
      center: CityHex(col: 1, row: 1),
    );

    final viewModel = CityProductionDialogViewModel.from(
      city,
      l10n: l10n,
      cityRuleset: CityRulesets.standard,
      research: ResearchState.empty,
      technologyRuleset: TechnologyRulesets.standard,
      mapData: null,
      cities: const [],
      units: const [],
      fieldImprovements: const [],
      productionPerTurn: 4,
    );

    expect(
      viewModel
          .itemForBuilding(CityBuildingType.granary)
          ?.buildingSortMetrics
          .food,
      2,
    );
    expect(
      viewModel
          .itemForBuilding(CityBuildingType.archive)
          ?.buildingSortMetrics
          .science,
      2,
    );
    expect(
      viewModel
          .itemForBuilding(CityBuildingType.housing)
          ?.buildingSortMetrics
          .maxControlledHexes,
      2,
    );
    expect(
      viewModel
          .itemForBuilding(CityBuildingType.storehouse)
          ?.buildingSortMetrics
          .foodDepositBonusPercent,
      20,
    );
  });
}

MapData _map() {
  return MapData(
    cols: 2,
    rows: 1,
    tiles: const [
      TileData(
        col: 0,
        row: 0,
        terrains: [TerrainType.plains],
        resources: [],
        height: 0,
      ),
      TileData(
        col: 1,
        row: 0,
        terrains: [TerrainType.hills],
        resources: [],
        height: 0,
      ),
    ],
  );
}

MapData _map3x3({({int col, int row})? coast, ({int col, int row})? ocean}) {
  return MapData(
    cols: 3,
    rows: 3,
    tiles: [
      for (var row = 0; row < 3; row++)
        for (var col = 0; col < 3; col++)
          TileData(
            col: col,
            row: row,
            terrains: ocean != null && ocean.col == col && ocean.row == row
                ? const [TerrainType.ocean]
                : coast != null && coast.col == col && coast.row == row
                ? const [TerrainType.coast]
                : const [TerrainType.grassland],
            resources: const [],
            height: 0,
          ),
    ],
  );
}
