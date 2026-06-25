import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/trade.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:aonw_core/map/domain/map_data.dart';
import 'package:aonw_core/map/domain/terrain_type.dart';
import 'package:test/test.dart';

void main() {
  group('CityResourceInventoryRules', () {
    test('counts resources controlled by player cities', () {
      final inventory = CityResourceInventoryRules.forPlayer(
        playerId: 'player_1',
        cities: const [
          GameCity(
            id: 'city_1',
            ownerPlayerId: 'player_1',
            name: 'Roma',
            center: CityHex(col: 1, row: 1),
            controlledHexes: [CityHex(col: 2, row: 1), CityHex(col: 1, row: 2)],
          ),
          GameCity(
            id: 'city_2',
            ownerPlayerId: 'player_2',
            name: 'Antium',
            center: CityHex(col: 0, row: 0),
          ),
        ],
        mapData: _map(),
      );

      expect(inventory.totalCount, 2);
      expect(inventory.distinctTypeCount, 2);
      expect(inventory.countFor(ResourceType.iron), 1);
      expect(inventory.countFor(ResourceType.wheat), 1);
      expect(inventory.countFor(ResourceType.gold), 0);
      expect(inventory.sources.map((source) => source.cityId).toSet(), {
        'city_1',
      });
    });

    test('building resource requirement uses city territory', () {
      const city = GameCity(
        id: 'city_1',
        ownerPlayerId: 'player_1',
        name: 'Roma',
        center: CityHex(col: 1, row: 1),
      );

      expect(
        CityBuildingRequirementRules.meetsRequirements(
          city: city,
          buildingType: CityBuildingType.forge,
          mapData: _map(),
        ),
        true,
      );
      expect(
        CityBuildingRequirementRules.meetsRequirements(
          city: city,
          buildingType: CityBuildingType.stable,
          mapData: _map(),
        ),
        false,
      );
    });

    test('deduplicates overlapping controlled hexes', () {
      final inventory = CityResourceInventoryRules.forPlayer(
        playerId: 'player_1',
        cities: const [
          GameCity(
            id: 'city_1',
            ownerPlayerId: 'player_1',
            name: 'Roma',
            center: CityHex(col: 1, row: 1),
          ),
          GameCity(
            id: 'city_2',
            ownerPlayerId: 'player_1',
            name: 'Neapolis',
            center: CityHex(col: 2, row: 2),
            controlledHexes: [CityHex(col: 1, row: 1)],
          ),
        ],
        mapData: _map(),
      );

      expect(inventory.countFor(ResourceType.iron), 1);
    });

    test('counts technology-gated resources only after reveal research', () {
      const city = GameCity(
        id: 'city_1',
        ownerPlayerId: 'player_1',
        name: 'Roma',
        center: CityHex(col: 2, row: 2),
      );

      final hiddenInventory = CityResourceInventoryRules.forPlayer(
        playerId: 'player_1',
        cities: const [city],
        mapData: _map(),
      );
      final revealedInventory = CityResourceInventoryRules.forPlayer(
        playerId: 'player_1',
        cities: const [city],
        mapData: _map(),
        research: _researchWith({TechnologyId.animalHusbandry}),
      );

      expect(hiddenInventory.countFor(ResourceType.horses), 0);
      expect(revealedInventory.countFor(ResourceType.horses), 1);
    });

    test('unit resource requirement uses all player cities', () {
      const capital = GameCity(
        id: 'city_1',
        ownerPlayerId: 'player_1',
        name: 'Roma',
        center: CityHex(col: 1, row: 1),
      );
      const horseCity = GameCity(
        id: 'city_2',
        ownerPlayerId: 'player_1',
        name: 'Neapolis',
        center: CityHex(col: 2, row: 2),
      );
      const rivalHorseCity = GameCity(
        id: 'city_3',
        ownerPlayerId: 'player_2',
        name: 'Antium',
        center: CityHex(col: 2, row: 2),
      );

      expect(
        UnitProductionRequirementRules.meetsRequirements(
          playerId: 'player_1',
          unitType: GameUnitType.cavalry,
          cities: const [capital, horseCity],
          mapData: _map(),
          research: _researchWith({TechnologyId.animalHusbandry}),
        ),
        isTrue,
      );
      expect(
        UnitProductionRequirementRules.meetsRequirements(
          playerId: 'player_1',
          unitType: GameUnitType.cavalry,
          cities: const [capital, rivalHorseCity],
          mapData: _map(),
          research: _researchWith({TechnologyId.animalHusbandry}),
        ),
        isFalse,
      );
    });

    test('empire resource network separates visible and hidden resources', () {
      const city = GameCity(
        id: 'city_1',
        ownerPlayerId: 'player_1',
        name: 'Roma',
        center: CityHex(col: 0, row: 1),
        controlledHexes: [CityHex(col: 1, row: 1), CityHex(col: 2, row: 2)],
      );

      final hiddenNetwork = EmpireResourceNetworkRules.forPlayer(
        playerId: 'player_1',
        cities: const [city],
        mapData: _map(),
        research: _researchWith({TechnologyId.animalHusbandry}),
      );
      final revealedNetwork = EmpireResourceNetworkRules.forPlayer(
        playerId: 'player_1',
        cities: const [city],
        mapData: _map(),
        research: _researchWith({
          TechnologyId.animalHusbandry,
          TechnologyId.combustion,
        }),
      );

      expect(hiddenNetwork.visibleCountFor(ResourceType.iron), 1);
      expect(hiddenNetwork.visibleCountFor(ResourceType.horses), 1);
      expect(hiddenNetwork.hiddenCountFor(ResourceType.oil), 1);
      expect(hiddenNetwork.controlsVisible(ResourceType.oil), isFalse);
      expect(hiddenNetwork.controlsHidden(ResourceType.oil), isTrue);

      expect(revealedNetwork.visibleCountFor(ResourceType.oil), 1);
      expect(revealedNetwork.hiddenCountFor(ResourceType.oil), 0);
    });

    test('empire resource network reports unit gates', () {
      const oilCity = GameCity(
        id: 'city_1',
        ownerPlayerId: 'player_1',
        name: 'Roma',
        center: CityHex(col: 0, row: 1),
      );
      const aluminiumCity = GameCity(
        id: 'city_2',
        ownerPlayerId: 'player_1',
        name: 'Neapolis',
        center: CityHex(col: 1, row: 0),
      );

      final hiddenOilNetwork = EmpireResourceNetworkRules.forPlayer(
        playerId: 'player_1',
        cities: const [oilCity],
        mapData: _map(),
      );
      final oilNetwork = EmpireResourceNetworkRules.forPlayer(
        playerId: 'player_1',
        cities: const [oilCity],
        mapData: _map(),
        research: _researchWith({TechnologyId.combustion}),
      );
      final aluminiumNetwork = EmpireResourceNetworkRules.forPlayer(
        playerId: 'player_1',
        cities: const [aluminiumCity],
        mapData: _map(),
        research: _researchWith({TechnologyId.flight}),
      );

      final hiddenTankGate = hiddenOilNetwork.unitGates.singleWhere(
        (gate) => gate.unitType == GameUnitType.tank,
      );
      expect(hiddenTankGate.satisfied, isFalse);
      expect(hiddenTankGate.blockedByHiddenResource, isTrue);
      expect(hiddenTankGate.hiddenControlledResources, {ResourceType.oil});

      final tankGate = oilNetwork.unitGates.singleWhere(
        (gate) => gate.unitType == GameUnitType.tank,
      );
      expect(tankGate.satisfied, isTrue);
      expect(tankGate.visibleControlledResources, {ResourceType.oil});

      final reconGate = aluminiumNetwork.unitGates.singleWhere(
        (gate) => gate.unitType == GameUnitType.reconPlane,
      );
      expect(reconGate.satisfied, isTrue);
      expect(reconGate.resourceChoices, {
        ResourceType.aluminium,
        ResourceType.oil,
      });
      expect(reconGate.visibleControlledResources, {ResourceType.aluminium});
    });

    test('empire resource network counts active imported resources', () {
      const capital = GameCity(
        id: 'city_1',
        ownerPlayerId: 'player_1',
        name: 'Roma',
        center: CityHex(col: 0, row: 0),
      );
      const horseImport = ResourceTradeAgreement(
        id: 'trade_1',
        exporterPlayerId: 'player_2',
        importerPlayerId: 'player_1',
        resource: ResourceType.horses,
        goldPerTurn: 3,
        remainingTurns: 8,
      );

      final network = EmpireResourceNetworkRules.forPlayer(
        playerId: 'player_1',
        cities: const [capital],
        mapData: _map(),
        resourceTradeAgreements: const [horseImport],
      );

      expect(network.visibleInventory.countFor(ResourceType.horses), 0);
      expect(network.importedCountFor(ResourceType.horses), 1);
      expect(network.visibleCountFor(ResourceType.horses), 1);
      expect(network.controlsVisible(ResourceType.horses), isTrue);

      final cavalryGate = network.unitGates.singleWhere(
        (gate) => gate.unitType == GameUnitType.cavalry,
      );
      expect(cavalryGate.satisfied, isTrue);
      expect(cavalryGate.visibleControlledResources, {ResourceType.horses});
    });

    test('late armor requires revealed oil in the empire', () {
      const oilCity = GameCity(
        id: 'city_1',
        ownerPlayerId: 'player_1',
        name: 'Roma',
        center: CityHex(col: 0, row: 1),
      );

      expect(
        UnitProductionRequirementRules.meetsRequirements(
          playerId: 'player_1',
          unitType: GameUnitType.tank,
          cities: const [oilCity],
          mapData: _map(),
        ),
        isFalse,
      );
      expect(
        UnitProductionRequirementRules.meetsRequirements(
          playerId: 'player_1',
          unitType: GameUnitType.tank,
          cities: const [oilCity],
          mapData: _map(),
          research: _researchWith({TechnologyId.combustion}),
        ),
        isTrue,
      );
    });

    test('unit resource requirement accepts imported resource', () {
      const capital = GameCity(
        id: 'city_1',
        ownerPlayerId: 'player_1',
        name: 'Roma',
        center: CityHex(col: 0, row: 0),
      );

      expect(
        UnitProductionRequirementRules.meetsRequirements(
          playerId: 'player_1',
          unitType: GameUnitType.cavalry,
          cities: const [capital],
          mapData: _map(),
        ),
        isFalse,
      );
      expect(
        UnitProductionRequirementRules.meetsRequirements(
          playerId: 'player_1',
          unitType: GameUnitType.cavalry,
          cities: const [capital],
          mapData: _map(),
          resourceTradeAgreements: const [
            ResourceTradeAgreement(
              id: 'trade_1',
              exporterPlayerId: 'player_2',
              importerPlayerId: 'player_1',
              resource: ResourceType.horses,
              goldPerTurn: 2,
              remainingTurns: 6,
            ),
          ],
        ),
        isTrue,
      );
    });

    test('recon plane accepts revealed aluminium or oil', () {
      const aluminiumCity = GameCity(
        id: 'city_1',
        ownerPlayerId: 'player_1',
        name: 'Roma',
        center: CityHex(col: 1, row: 0),
      );
      const oilCity = GameCity(
        id: 'city_2',
        ownerPlayerId: 'player_1',
        name: 'Neapolis',
        center: CityHex(col: 0, row: 1),
      );

      expect(
        UnitProductionRequirementRules.meetsRequirements(
          playerId: 'player_1',
          unitType: GameUnitType.reconPlane,
          cities: const [aluminiumCity],
          mapData: _map(),
          research: _researchWith({TechnologyId.flight}),
        ),
        isTrue,
      );
      expect(
        UnitProductionRequirementRules.meetsRequirements(
          playerId: 'player_1',
          unitType: GameUnitType.reconPlane,
          cities: const [oilCity],
          mapData: _map(),
          research: _researchWith({TechnologyId.combustion}),
        ),
        isTrue,
      );
      expect(
        UnitProductionRequirementRules.missingResourceChoices(
          playerId: 'player_1',
          unitType: GameUnitType.reconPlane,
          cities: const [aluminiumCity],
          mapData: _map(),
        ),
        {ResourceType.aluminium, ResourceType.oil},
      );
    });
  });
}

MapData _map() {
  return MapData(
    cols: 3,
    rows: 3,
    tiles: [
      for (var row = 0; row < 3; row++)
        for (var col = 0; col < 3; col++)
          TileData(
            col: col,
            row: row,
            terrains: const [TerrainType.grassland],
            resources: switch ((col, row)) {
              (1, 0) => const [ResourceType.aluminium],
              (0, 1) => const [ResourceType.oil],
              (1, 1) => const [ResourceType.iron],
              (2, 1) => const [ResourceType.wheat],
              (2, 2) => const [ResourceType.horses],
              (0, 0) => const [ResourceType.gold],
              _ => const [],
            },
            height: 0,
          ),
    ],
  );
}

ResearchState _researchWith(Set<TechnologyId> technologyIds) {
  return ResearchState(
    players: {
      'player_1': PlayerResearchState(unlockedTechnologyIds: technologyIds),
    },
  );
}
