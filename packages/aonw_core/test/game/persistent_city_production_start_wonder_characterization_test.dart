import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

const _playerId = 'player_1';
const _otherPlayerId = 'player_2';

void main() {
  group('Persistent startWonder characterization', () {
    final unavailableCases =
        <
          ({
            String name,
            WonderAvailabilityStatus status,
            StartWonderCommand command,
            PersistentGameState Function() buildState,
          })
        >[
          (
            name: 'completed',
            status: WonderAvailabilityStatus.completed,
            command: const StartWonderCommand(
              'city_1',
              WonderType.greatLibrary,
            ),
            buildState: () => _persistentState(
              cities: [_city()],
              research: _writingResearch(),
              wonderRegistry: WonderRegistry.empty.complete(
                type: WonderType.greatLibrary,
                playerId: _otherPlayerId,
              ),
            ),
          ),
          (
            name: 'technologyLocked',
            status: WonderAvailabilityStatus.technologyLocked,
            command: const StartWonderCommand(
              'city_1',
              WonderType.greatLibrary,
            ),
            buildState: () => _persistentState(cities: [_city()]),
          ),
          (
            name: 'requirementsMissing',
            status: WonderAvailabilityStatus.requirementsMissing,
            command: const StartWonderCommand('city_1', WonderType.petra),
            buildState: () => _persistentState(
              cities: [_city()],
              research: _researchWith(TechnologyId.stoneworking),
            ),
          ),
          (
            name: 'cityAlreadyBuildingWonder',
            status: WonderAvailabilityStatus.cityAlreadyBuildingWonder,
            command: const StartWonderCommand(
              'city_1',
              WonderType.greatLibrary,
            ),
            buildState: () => _persistentState(
              cities: [
                _city(
                  productionQueue: CityProductionQueue.wonder(
                    wonderType: WonderType.hangingGardens,
                    investedProduction: 11,
                  ),
                ),
              ],
              research: _writingResearch(),
            ),
          ),
          (
            name: 'playerAlreadyBuildingWonder',
            status: WonderAvailabilityStatus.playerAlreadyBuildingWonder,
            command: const StartWonderCommand(
              'city_1',
              WonderType.greatLibrary,
            ),
            buildState: () => _persistentState(
              cities: [
                _city(),
                _city(
                  id: 'peer_city',
                  center: const CityHex(col: 2, row: 2),
                  productionQueue: CityProductionQueue.wonder(
                    wonderType: WonderType.hangingGardens,
                    investedProduction: 13,
                  ),
                ),
              ],
              research: _writingResearch(),
            ),
          ),
        ];

    for (final unavailableCase in unavailableCases) {
      test(
        'rejects ${unavailableCase.name} without changing state identity',
        () {
          final state = unavailableCase.buildState();
          final cities = state.cities;
          final targetCity = cities.singleWhere(
            (city) => city.id == unavailableCase.command.cityId,
          );
          final existingQueues = {
            for (final city in cities) city.id: ?city.productionQueue,
          };
          final availability = WonderAvailabilityPolicy.availabilityFor(
            city: targetCity,
            wonderType: unavailableCase.command.wonderType,
            cities: cities,
            registry: state.wonderRegistry,
            research: state.research,
            mapTiles: _mapTiles(),
          );

          expect(availability.status, unavailableCase.status);

          final result = _startWonder(state, command: unavailableCase.command);

          expect(result.accepted, isFalse);
          expect(result.reason, 'wonder_not_available');
          expect(result.events, isEmpty);
          expect(result.state, same(state));
          expect(result.state.cities, same(cities));
          expect(
            result.state.cities.singleWhere(
              (city) => city.id == unavailableCase.command.cityId,
            ),
            same(targetCity),
          );
          for (final entry in existingQueues.entries) {
            expect(
              result.state.cities
                  .singleWhere((city) => city.id == entry.key)
                  .productionQueue,
              same(entry.value),
              reason: '${unavailableCase.name}: ${entry.key}',
            );
          }
        },
      );
    }

    test('rejects a missing city without changing any state identity', () {
      final state = _persistentState(
        cities: [_city(id: 'sentinel_city', productionQueue: _buildingQueue())],
      );
      final cities = state.cities;
      final sentinel = cities.single;
      final queue = sentinel.productionQueue;

      final result = _startWonder(
        state,
        command: const StartWonderCommand(
          'missing_city',
          WonderType.greatLibrary,
        ),
      );

      expect(result.accepted, isFalse);
      expect(result.reason, 'city_not_found');
      expect(result.events, isEmpty);
      expect(result.state, same(state));
      expect(result.state.cities, same(cities));
      expect(result.state.cities.single, same(sentinel));
      expect(result.state.cities.single.productionQueue, same(queue));
    });

    test('checks city control before wonder availability', () {
      final state = _persistentState(
        cities: [
          _city(
            ownerPlayerId: _otherPlayerId,
            productionQueue: CityProductionQueue.wonder(
              wonderType: WonderType.hangingGardens,
              investedProduction: 11,
            ),
          ),
        ],
      );
      final cities = state.cities;
      final city = cities.single;
      final queue = city.productionQueue;

      final result = _startWonder(state);

      expect(result.accepted, isFalse);
      expect(result.reason, 'city_not_controlled');
      expect(result.events, isEmpty);
      expect(result.state, same(state));
      expect(result.state.cities, same(cities));
      expect(result.state.cities.single, same(city));
      expect(result.state.cities.single.productionQueue, same(queue));
    });

    test('rejects a different active wonder with all identities intact', () {
      final activeQueue = CityProductionQueue.wonder(
        wonderType: WonderType.hangingGardens,
        investedProduction: 13,
      );
      final state = _persistentState(
        cities: [_city(productionQueue: activeQueue, productionOverflow: 7)],
        research: _writingResearch(),
      );
      final cities = state.cities;
      final city = cities.single;
      final queue = city.productionQueue;

      final result = _startWonder(state);

      expect(result.accepted, isFalse);
      expect(result.reason, 'wonder_not_available');
      expect(result.events, isEmpty);
      expect(result.state, same(state));
      expect(result.state.cities, same(cities));
      expect(result.state.cities.single, same(city));
      expect(result.state.cities.single.productionQueue, same(queue));
    });

    test(
      'replaces a non-wonder queue with fresh identities and keeps investment',
      () {
        final targetQueue = _buildingQueue(investedProduction: 17);
        final state = _persistentState(
          cities: [
            _city(productionQueue: targetQueue, productionOverflow: 9),
            _city(id: 'unrelated_city', center: const CityHex(col: 2, row: 2)),
          ],
          research: _writingResearch(),
        );
        final cities = state.cities;
        final city = cities.first;
        final queue = city.productionQueue;
        final unrelatedCity = cities.last;

        final result = _startWonder(state);

        final updatedCity = result.state.cities.first;
        final updatedQueue = updatedCity.productionQueue;
        expect(result.accepted, isTrue);
        expect(result.reason, isNull);
        expect(result.events, isEmpty);
        expect(result.state, isNot(same(state)));
        expect(result.state.cities, isNot(same(cities)));
        expect(updatedCity, isNot(same(city)));
        expect(updatedQueue, isNot(same(queue)));
        expect(result.state.cities.last, same(unrelatedCity));
        expect(
          updatedQueue?.target,
          const WonderProductionTarget(WonderType.greatLibrary),
        );
        expect(updatedQueue?.investedProduction, 17);
        expect(updatedCity.productionOverflow, 9);
      },
    );
  });
}

PersistentCityProductionResult _startWonder(
  PersistentGameState state, {
  StartWonderCommand command = const StartWonderCommand(
    'city_1',
    WonderType.greatLibrary,
  ),
}) {
  return const PersistentCityProductionResolver().startWonder(
    state: state,
    command: command,
    actorPlayerId: _playerId,
    mapTiles: _mapTiles(),
  );
}

PersistentGameState _persistentState({
  required List<GameCity> cities,
  ResearchState research = ResearchState.empty,
  WonderRegistry wonderRegistry = WonderRegistry.empty,
}) {
  return PersistentGameState.snapshot(
    cities: cities,
    research: research,
    playerGold: const {_playerId: 41, _otherPlayerId: 23},
    wonderRegistry: wonderRegistry,
  );
}

GameCity _city({
  String id = 'city_1',
  String ownerPlayerId = _playerId,
  CityHex center = const CityHex(col: 1, row: 1),
  CityProductionQueue? productionQueue,
  int productionOverflow = 0,
}) {
  return GameCity.snapshot(
    id: id,
    ownerPlayerId: ownerPlayerId,
    name: id,
    center: center,
    productionQueue: productionQueue,
    productionOverflow: productionOverflow,
  );
}

CityProductionQueue _buildingQueue({int investedProduction = 5}) {
  return CityProductionQueue.building(
    buildingType: CityBuildingType.granary,
    investedProduction: investedProduction,
  );
}

ResearchState _writingResearch() {
  return _researchWith(TechnologyId.writing);
}

ResearchState _researchWith(TechnologyId technologyId) {
  return ResearchState(
    players: {
      _playerId: PlayerResearchState(unlockedTechnologyIds: {technologyId}),
    },
  );
}

MapTileLookup _mapTiles() {
  return WorldMapReadView(
    WorldMap(
      cols: 3,
      rows: 3,
      tiles: [
        for (var row = 0; row < 3; row++)
          for (var col = 0; col < 3; col++)
            WorldTile(
              coordinate: HexCoord(col: col, row: row),
              terrains: const [TerrainType.grassland],
              resources: const [],
              height: 0,
            ),
      ],
    ),
  );
}
