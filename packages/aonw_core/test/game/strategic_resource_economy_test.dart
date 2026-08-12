import 'package:aonw_core/domain.dart';
import 'package:aonw_core/game/domain/turn/economy/turn_economy_state.dart';
import 'package:aonw_core/game/domain/turn/economy/turn_resource_trade_economy_advancer.dart';
import 'package:test/test.dart';

void main() {
  group('strategic resource economy', () {
    test('stockpile bundles reject presence-only strategic resources', () {
      expect(
        () => StrategicResourceBundle(const {ResourceType.iron: 1}),
        throwsArgumentError,
      );
    });

    test('extracts a revealed resource from a matching improved source', () {
      final projection = StrategicResourceProductionRules.forPlayer(
        playerId: 'p1',
        cities: const [_city],
        fieldImprovements: const [
          FieldImprovement(
            hex: CityHex(col: 1, row: 1),
            type: FieldImprovementType.oilWell,
            builtByCityId: 'city_1',
          ),
        ],
        mapTiles: _resourceMap(ResourceType.oil),
        research: _research({TechnologyId.combustion}),
      );

      expect(projection.output, StrategicResourceBundle.oilOne);
      expect(projection.sources, hasLength(1));
      expect(projection.sources.single.cityId, 'city_1');
      expect(projection.sources.single.amountPerTurn, 1);
    });

    test('does not extract a hidden or incorrectly improved resource', () {
      final hidden = StrategicResourceProductionRules.forPlayer(
        playerId: 'p1',
        cities: const [_city],
        fieldImprovements: const [
          FieldImprovement(
            hex: CityHex(col: 1, row: 1),
            type: FieldImprovementType.oilWell,
            builtByCityId: 'city_1',
          ),
        ],
        mapTiles: _resourceMap(ResourceType.oil),
        research: ResearchState.empty,
      );
      final wrongImprovement = StrategicResourceProductionRules.forPlayer(
        playerId: 'p1',
        cities: const [_city],
        fieldImprovements: const [
          FieldImprovement(
            hex: CityHex(col: 1, row: 1),
            type: FieldImprovementType.mine,
            builtByCityId: 'city_1',
          ),
        ],
        mapTiles: _resourceMap(ResourceType.oil),
        research: _research({TechnologyId.combustion}),
      );

      expect(hidden.output, StrategicResourceBundle.empty);
      expect(wrongImprovement.output, StrategicResourceBundle.empty);
    });

    test('reserves a unit cost and refunds it before replacement quoting', () {
      final state = DomainState.snapshot(
        matchRules: MatchRules.standard,
        playerGold: const {'p1': 10},
        cities: const [_city],
        research: _research({
          TechnologyId.combustion,
          TechnologyId.flight,
          TechnologyId.massProduction,
        }),
        strategicResources: StrategicResourceAccounts(
          byPlayerId: {
            'p1': StrategicResourceStockpile(
              onHand: StrategicResourceBundle.oilTwo,
            ),
          },
        ),
      );
      const resolver = DomainCityProductionResolver();
      final tank = resolver.startUnitProduction(
        state: state,
        command: const StartUnitProductionCommand('city_1', GameUnitType.tank),
        actorPlayerId: 'p1',
        mapView: _resourceMap(null),
      );

      expect(tank.accepted, isTrue);
      expect(
        tank.state.strategicResources
            .forPlayer('p1')
            .amountFor(ResourceType.oil),
        0,
      );
      expect(
        tank.state.cities.single.productionQueue!.resourceAllocation,
        StrategicResourceBundle.oilTwo,
      );

      final recon = resolver.startUnitProduction(
        state: tank.state,
        command: const StartUnitProductionCommand(
          'city_1',
          GameUnitType.reconPlane,
        ),
        actorPlayerId: 'p1',
        mapView: _resourceMap(null),
      );

      expect(recon.accepted, isTrue);
      expect(
        recon.state.strategicResources
            .forPlayer('p1')
            .amountFor(ResourceType.oil),
        1,
      );
      expect(
        recon.state.cities.single.productionQueue!.resourceAllocation,
        StrategicResourceBundle.oilOne,
      );
    });

    test('moves one stockpiled unit through an active trade agreement', () {
      final state = _economyState(
        playerGold: const {'exporter': 0, 'importer': 5},
        strategicResources: StrategicResourceAccounts(
          byPlayerId: {
            'exporter': StrategicResourceStockpile(
              onHand: StrategicResourceBundle.oilOne,
            ),
          },
        ),
        agreements: const [
          ResourceTradeAgreement(
            id: 'oil_trade',
            exporterPlayerId: 'exporter',
            importerPlayerId: 'importer',
            resource: ResourceType.oil,
            goldPerTurn: 2,
            remainingTurns: 2,
          ),
        ],
      );

      final delivered = TurnResourceTradeEconomyAdvancer.advance(
        state: state,
        playerIds: const ['importer'],
      );

      expect(delivered.playerGold, {'exporter': 2, 'importer': 3});
      expect(
        delivered.strategicResources
            .forPlayer('exporter')
            .amountFor(ResourceType.oil),
        0,
      );
      expect(
        delivered.strategicResources
            .forPlayer('importer')
            .amountFor(ResourceType.oil),
        1,
      );
      expect(delivered.resourceTradeAgreements.single.remainingTurns, 1);
    });

    test('failed stockpile delivery does not charge the importer', () {
      final state = _economyState(
        playerGold: const {'exporter': 0, 'importer': 5},
        agreements: const [
          ResourceTradeAgreement(
            id: 'oil_trade',
            exporterPlayerId: 'exporter',
            importerPlayerId: 'importer',
            resource: ResourceType.oil,
            goldPerTurn: 2,
            remainingTurns: 1,
          ),
        ],
      );

      final failed = TurnResourceTradeEconomyAdvancer.advance(
        state: state,
        playerIds: const ['importer'],
      );

      expect(failed.playerGold, state.playerGold);
      expect(failed.strategicResources, state.strategicResources);
      expect(failed.resourceTradeAgreements, isEmpty);
    });

    test('canonical state round-trips accounts and queue allocations', () {
      final source = DomainState.snapshot(
        playerGold: const {'p1': 4},
        strategicResources: StrategicResourceAccounts(
          byPlayerId: {
            'p1': StrategicResourceStockpile(
              onHand: StrategicResourceBundle.aluminiumOne,
            ),
          },
        ),
        cities: [
          _city.copyWith(
            productionQueue: CityProductionQueue.unit(
              unitType: GameUnitType.tank,
              investedProduction: 7,
              resourceAllocation: StrategicResourceBundle.oilTwo,
            ),
          ),
        ],
      );

      final restored = CanonicalGameSnapshotCodec.decodeDomainState(
        CanonicalGameSnapshotCodec.encodeDomainState(source),
      );

      expect(restored.strategicResources, source.strategicResources);
      expect(
        restored.cities.single.productionQueue,
        source.cities.single.productionQueue,
      );
    });
  });
}

const _city = GameCity(
  id: 'city_1',
  ownerPlayerId: 'p1',
  name: 'City',
  center: CityHex(col: 1, row: 1),
  population: 8,
);

ResearchState _research(Set<TechnologyId> technologies) => ResearchState(
  players: {'p1': PlayerResearchState(unlockedTechnologyIds: technologies)},
);

WorldMap _resourceMap(ResourceType? resource) => WorldMap(
  cols: 3,
  rows: 3,
  mapName: 'strategic_resources',
  tiles: [
    for (var row = 0; row < 3; row++)
      for (var col = 0; col < 3; col++)
        WorldTile.at(
          coordinate: HexCoord(col: col, row: row),
          terrains: const [TerrainType.grassland],
          resources: col == 1 && row == 1 && resource != null
              ? [resource]
              : const [],
          height: 0,
        ),
  ],
);

TurnEconomyState _economyState({
  required Map<String, int> playerGold,
  StrategicResourceAccounts strategicResources =
      StrategicResourceAccounts.empty,
  List<ResourceTradeAgreement> agreements = const [],
}) => TurnEconomyState(
  playerGold: playerGold,
  playerWarWeariness: const {},
  playerStabilityNet: const {},
  strategicResources: strategicResources,
  units: const [],
  cities: const [],
  artifacts: const [],
  fieldImprovements: const [],
  fogOfWar: FogOfWarState.empty,
  research: ResearchState.empty,
  wonderRegistry: WonderRegistry.empty,
  diplomacy: DiplomacyState.empty,
  resourceTradeAgreements: agreements,
  mapObjectiveHoldStatesByObjectiveId: const {},
);
