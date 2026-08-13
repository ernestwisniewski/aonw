import 'package:aonw_core/domain.dart';
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
      expect(
        projection.sources.single.improvement,
        FieldImprovementType.oilWell,
      );
      expect(projection.sources.single.amountPerTurn, 1);
      expect(
        StrategicResourceProductionRules.outputForPlayer(
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
        ),
        projection.output,
      );
    });

    test('infers an improvement owner from controlled territory', () {
      final output = StrategicResourceProductionRules.outputForPlayer(
        playerId: 'p1',
        cities: const [_city],
        fieldImprovements: const [
          FieldImprovement(
            hex: CityHex(col: 1, row: 1),
            type: FieldImprovementType.oilWell,
          ),
        ],
        mapTiles: _resourceMap(ResourceType.oil),
        research: _research({TechnologyId.combustion}),
      );

      expect(output, StrategicResourceBundle.oilOne);
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

    test('honors an explicit resource option and rejects an invalid index', () {
      final state = DomainState.snapshot(
        matchRules: MatchRules.standard,
        cities: const [_city],
        research: _research({TechnologyId.flight}),
        strategicResources: StrategicResourceAccounts(
          byPlayerId: {
            'p1': StrategicResourceStockpile(
              onHand: StrategicResourceBundle({
                ResourceType.oil: 1,
                ResourceType.aluminium: 1,
              }),
            ),
          },
        ),
      );
      const resolver = DomainCityProductionResolver();

      final selected = resolver.startUnitProduction(
        state: state,
        command: const StartUnitProductionCommand(
          'city_1',
          GameUnitType.reconPlane,
          resourceOptionIndex: 0,
        ),
        actorPlayerId: 'p1',
        mapView: _resourceMap(null),
      );

      expect(selected.accepted, isTrue);
      expect(
        selected.state.cities.single.productionQueue!.resourceAllocation,
        StrategicResourceBundle.aluminiumOne,
      );
      expect(
        selected.state.strategicResources
            .forPlayer('p1')
            .amountFor(ResourceType.oil),
        1,
      );

      final invalid = resolver.startUnitProduction(
        state: state,
        command: const StartUnitProductionCommand(
          'city_1',
          GameUnitType.reconPlane,
          resourceOptionIndex: 9,
        ),
        actorPlayerId: 'p1',
        mapView: _resourceMap(null),
      );
      expect(invalid.accepted, isFalse);
      expect(invalid.reason, 'unit_production_invalid_resource_option');
      expect(invalid.state, same(state));
    });

    test('selecting the active allocation again is an identity no-op', () {
      final queue = CityProductionQueue.unit(
        unitType: GameUnitType.tank,
        investedProduction: 12,
        resourceAllocation: StrategicResourceBundle.oilTwo,
      );
      final city = _city.copyWith(productionQueue: queue);
      final state = DomainState.snapshot(
        matchRules: MatchRules.standard,
        cities: [city],
        research: _research({
          TechnologyId.combustion,
          TechnologyId.massProduction,
        }),
      );

      final result = const DomainCityProductionResolver().startUnitProduction(
        state: state,
        command: const StartUnitProductionCommand('city_1', GameUnitType.tank),
        actorPlayerId: 'p1',
        mapView: _resourceMap(null),
      );

      expect(result.accepted, isTrue);
      expect(result.state, same(state));
      expect(result.state.cities.single.productionQueue, same(queue));
      expect(result.state.strategicResources, same(state.strategicResources));
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
