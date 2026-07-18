import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

import 'persistent_city_production_rush_characterization_test_support.dart';

void main() {
  group('Persistent rushProduction rejection characterization', () {
    final granaryCost = CityProductionRules.targetCost(
      const BuildingProductionTarget(CityBuildingType.granary),
    );
    final cases = [
      ..._rushPrecedenceRejectionCases(),
      ...rushAvailabilityRejectionCases(granaryCost),
    ];

    test('corpus covers the exact rejection reason vocabulary', () {
      expect(cases.map((rejectionCase) => rejectionCase.reason).toSet(), {
        'city_not_found',
        'city_not_controlled',
        'production_queue_empty',
        'project_cannot_be_rushed',
        'rush_production_unavailable',
      });
    });

    for (final rejectionCase in cases) {
      test(rejectionCase.name, () {
        final result = rushCharacterization(
          rejectionCase.state,
          command: rejectionCase.command,
          actorPlayerId: rejectionCase.actorPlayerId,
        );

        expectRejectedRushIdentity(
          before: rejectionCase.state,
          result: result,
          reason: rejectionCase.reason,
        );
      });
    }
  });

  group('Persistent rushProduction acceptance characterization', () {
    test('incomplete building replaces only city and treasury slices', () {
      final queue = rushCharacterizationBuildingQueue();
      final state = rushCharacterizationState(
        cities: rushCharacterizationCities(
          rushCharacterizationCity(
            productionQueue: queue,
            productionOverflow: 5,
          ),
        ),
        playerGold: const {
          rushCharacterizationPlayerId: 20,
          rushCharacterizationOtherPlayerId: 23,
        },
      );

      final result = rushCharacterization(state);

      expect(result.accepted, isTrue);
      expect(result.reason, isNull);
      expect(result.events, isEmpty);
      expect(result.state, isNot(same(state)));
      expectRushSliceIdentities(
        state,
        result.state,
        citiesSame: false,
        unitsSame: null,
        playerGoldSame: false,
      );
      expectRushUnitElementsShared(state, result.state);
      final updatedCity = result.state.cities.first;
      expect(updatedCity, isNot(same(state.cities.first)));
      expect(updatedCity.productionQueue, isNot(same(queue)));
      expect(updatedCity.productionQueue?.investedProduction, 1);
      expect(updatedCity.productionOverflow, 5);
      expect(result.state.cities.last, same(state.cities.last));
      expect(result.state.playerGold[rushCharacterizationPlayerId], 18);
    });

    test(
      'forwards custom city rules, map, stability and pace to completion',
      () {
        final cityRuleset = rushCharacterizationCustomCityRuleset();
        final stabilityRuleset = StabilityRuleset.standard.copyWith(
          unrestThreshold: -1,
        );
        final queue = rushCharacterizationBuildingQueue(investedProduction: 28);
        final state = rushCharacterizationState(
          cities: rushCharacterizationCities(
            rushCharacterizationCity(
              controlledHexes: const [CityHex(col: 2, row: 1)],
              workedHexes: const [CityHex(col: 2, row: 1)],
              productionQueue: queue,
              productionOverflow: 9,
            ),
          ),
          playerGold: const {
            rushCharacterizationPlayerId: 12,
            rushCharacterizationOtherPlayerId: 23,
          },
          playerStabilityNet: const {
            rushCharacterizationPlayerId: -1,
            rushCharacterizationOtherPlayerId: 2,
          },
        );
        final map = rushCharacterizationMap(workedTerrain: TerrainType.plains);
        const pace = PaceBalance.standard60;
        expect(
          CityProductionRules.targetCost(
            queue.target,
            ruleset: cityRuleset,
            paceBalance: pace,
          ),
          34,
        );

        final result = rushCharacterization(
          state,
          mapTiles: map,
          cityRuleset: cityRuleset,
          stabilityRuleset: stabilityRuleset,
          paceBalance: pace,
        );

        expect(result.accepted, isTrue);
        expect(result.reason, isNull);
        expect(result.state.playerGold[rushCharacterizationPlayerId], 0);
        final updatedCity = result.state.cities.first;
        expect(updatedCity.productionQueue, isNull);
        expect(updatedCity.productionOverflow, 0);
        expect(updatedCity.buildings, contains(CityBuildingType.granary));
        final event = result.events.single as CityBuiltBuildingEvent;
        expect(event.cityId, 'city_1');
        expect(event.buildingType, CityBuildingType.granary);
        expectRushSliceIdentities(
          state,
          result.state,
          citiesSame: false,
          unitsSame: null,
          playerGoldSame: false,
        );
        expectRushUnitElementsShared(state, result.state);
        expect(result.state.cities.last, same(state.cities.last));
      },
    );

    test('forwards a custom technology ruleset into unit rush amount', () {
      final cityRuleset = rushCharacterizationCustomCityRuleset();
      final queue = rushCharacterizationUnitQueue();
      final state = rushCharacterizationState(
        cities: rushCharacterizationCities(
          rushCharacterizationCity(productionQueue: queue),
        ),
        playerGold: const {
          rushCharacterizationPlayerId: 16,
          rushCharacterizationOtherPlayerId: 23,
        },
        research: rushCharacterizationLogisticsResearch(),
      );

      final result = rushCharacterization(
        state,
        cityRuleset: cityRuleset,
        technologyRuleset: rushCharacterizationTechnologyRuleset(),
      );

      expect(result.accepted, isTrue);
      expect(result.events, isEmpty);
      expect(result.state.cities.first.productionQueue?.investedProduction, 8);
      expect(result.state.playerGold[rushCharacterizationPlayerId], 0);
      expectRushSliceIdentities(
        state,
        result.state,
        citiesSame: false,
        unitsSame: null,
        playerGoldSame: false,
      );
      expectRushUnitElementsShared(state, result.state);
    });

    test('legacy: Hero Sword does not grant XP to a rushed unit', () {
      final unitCost = CityProductionRules.targetCost(
        const UnitProductionTarget(GameUnitType.warrior),
      );
      final heroSword = rushCharacterizationHeroSword();
      final state = rushCharacterizationState(
        cities: rushCharacterizationCities(
          rushCharacterizationCity(
            productionQueue: rushCharacterizationUnitQueue(
              investedProduction: unitCost - 1,
            ),
          ),
        ),
        playerGold: const {
          rushCharacterizationPlayerId: 2,
          rushCharacterizationOtherPlayerId: 23,
        },
        artifacts: [heroSword],
      );
      expect(
        WorldArtifactBonuses.producedUnitExperienceFor(
          cityId: 'city_1',
          artifacts: state.artifacts,
        ),
        2,
      );

      final result = rushCharacterization(state);

      expect(result.accepted, isTrue);
      final produced = result.state.units.last;
      expect(produced.id, 'city_1_warrior_1');
      expect(produced.type, GameUnitType.warrior);
      expect(produced.coordinate, const HexCoordinate(col: 1, row: 1));
      expect(
        produced.experiencePoints,
        0,
        reason: 'Characterizes the current rush-only Hero Sword XP gap.',
      );
      expect(result.state.cities.first.productionQueue, isNull);
      final event = result.events.single as CityProducedUnitEvent;
      expect(event.cityId, 'city_1');
      expect(event.unitType, GameUnitType.warrior);
      expect(event.producedUnitId, produced.id);
      expectRushSliceIdentities(
        state,
        result.state,
        citiesSame: false,
        unitsSame: false,
        playerGoldSame: false,
      );
      expect(result.state.units.first, same(state.units.first));
      expect(result.state.artifacts.single, same(heroSword));
    });

    test(
      'legacy: blocked spawn accepts, spends gold and keeps complete queue',
      () {
        final unitCost = CityProductionRules.targetCost(
          const UnitProductionTarget(GameUnitType.warrior),
        );
        final queue = rushCharacterizationUnitQueue(
          investedProduction: unitCost - 1,
        );
        final state = rushCharacterizationState(
          cities: rushCharacterizationCities(
            rushCharacterizationCity(
              productionQueue: queue,
              productionOverflow: 7,
            ),
          ),
          playerGold: const {
            rushCharacterizationPlayerId: 2,
            rushCharacterizationOtherPlayerId: 23,
          },
          units: rushCharacterizationSpawnBlockers(),
        );

        final result = rushCharacterization(state);

        expect(result.accepted, isTrue);
        expect(result.reason, isNull);
        expect(result.events, isEmpty);
        expect(result.state.playerGold[rushCharacterizationPlayerId], 0);
        expectRushUnitElementsShared(state, result.state);
        final updatedCity = result.state.cities.first;
        expect(updatedCity.productionQueue, isNot(same(queue)));
        expect(updatedCity.productionQueue?.investedProduction, unitCost);
        expect(
          updatedCity.productionQueue?.isComplete,
          isTrue,
          reason: 'Characterizes the current accepted-but-blocked queue state.',
        );
        expect(updatedCity.productionOverflow, 7);
        expectRushSliceIdentities(
          state,
          result.state,
          citiesSame: false,
          unitsSame: null,
          playerGoldSame: false,
        );
      },
    );

    test(
      'custom wonder completion applies effects and ordered rival refund',
      () {
        final ruleset = rushCharacterizationWonderRuleset();
        const pace = PaceBalance.standard60;
        const target = WonderProductionTarget(WonderType.hangingGardens);
        final wonderCost = CityProductionRules.targetCost(
          target,
          wonderRuleset: ruleset,
          paceBalance: pace,
        );
        expect(wonderCost, 17);
        final rivalQueue = CityProductionQueue.wonder(
          wonderType: WonderType.hangingGardens,
          investedProduction: 9,
        );
        final sentinel = rushCharacterizationSentinelCity();
        final state = rushCharacterizationState(
          cities: [
            rushCharacterizationCity(
              productionQueue: CityProductionQueue.wonder(
                wonderType: WonderType.hangingGardens,
                investedProduction: wonderCost - 1,
              ),
              productionOverflow: 5,
            ),
            rushCharacterizationCity(
              id: 'rival_city',
              ownerPlayerId: rushCharacterizationOtherPlayerId,
              center: const CityHex(col: 3, row: 3),
              productionQueue: rivalQueue,
              productionOverflow: 2,
            ),
            sentinel,
          ],
          playerGold: const {
            rushCharacterizationPlayerId: 2,
            rushCharacterizationOtherPlayerId: 23,
          },
        );

        final result = rushCharacterization(
          state,
          wonderRuleset: ruleset,
          paceBalance: pace,
        );

        expect(result.accepted, isTrue);
        expect(result.reason, isNull);
        expect(
          result.state.wonderRegistry.ownerOf(WonderType.hangingGardens),
          rushCharacterizationPlayerId,
        );
        final host = result.state.cities[0];
        expect(host.productionQueue, isNull);
        expect(host.wonders, contains(WonderType.hangingGardens));
        expect(host.productionOverflow, 3);
        final rival = result.state.cities[1];
        expect(rival.productionQueue, isNull);
        expect(rival.productionOverflow, 11);
        expect(result.state.cities[2], same(sentinel));
        expect(result.state.playerGold[rushCharacterizationPlayerId], 7);
        expect(result.state.playerGold[rushCharacterizationOtherPlayerId], 23);
        expect(result.events, hasLength(2));
        final built = result.events[0] as CityBuiltWonderEvent;
        expect(built.cityId, 'city_1');
        expect(built.ownerPlayerId, rushCharacterizationPlayerId);
        expect(built.wonderType, WonderType.hangingGardens);
        final refunded = result.events[1] as WonderProductionRefundedEvent;
        expect(refunded.cityId, 'rival_city');
        expect(refunded.ownerPlayerId, rushCharacterizationOtherPlayerId);
        expect(refunded.wonderType, WonderType.hangingGardens);
        expect(refunded.refundedProduction, 9);
        expectRushSliceIdentities(
          state,
          result.state,
          citiesSame: false,
          unitsSame: null,
          playerGoldSame: false,
          wonderRegistrySame: false,
        );
        expectRushUnitElementsShared(state, result.state);
      },
    );

    test(
      'precompleted wonder refunds the rushed queue after spending gold',
      () {
        const target = WonderProductionTarget(WonderType.greatLibrary);
        final wonderCost = CityProductionRules.targetCost(target);
        final queue = CityProductionQueue.wonder(
          wonderType: WonderType.greatLibrary,
          investedProduction: wonderCost - 1,
        );
        final sentinel = rushCharacterizationSentinelCity();
        final state = rushCharacterizationState(
          cities: [
            rushCharacterizationCity(
              productionQueue: queue,
              productionOverflow: 4,
            ),
            sentinel,
          ],
          playerGold: const {
            rushCharacterizationPlayerId: 9,
            rushCharacterizationOtherPlayerId: 23,
          },
        );
        final registry = state.wonderRegistry;
        expect(
          registry.ownerOf(WonderType.greatLibrary),
          rushCharacterizationOtherPlayerId,
        );

        final result = rushCharacterization(state);

        expect(result.accepted, isTrue);
        expect(result.reason, isNull);
        expect(result.state.playerGold[rushCharacterizationPlayerId], 7);
        expect(result.state.playerGold[rushCharacterizationOtherPlayerId], 23);
        final refundedCity = result.state.cities.first;
        expect(refundedCity.productionQueue, isNull);
        expect(refundedCity.productionOverflow, wonderCost + 4);
        expect(refundedCity.wonders, isEmpty);
        expect(result.state.cities.last, same(sentinel));
        expect(result.state.wonderRegistry, same(registry));
        expect(result.events, hasLength(1));
        final refunded = result.events[0] as WonderProductionRefundedEvent;
        expect(refunded.cityId, 'city_1');
        expect(refunded.ownerPlayerId, rushCharacterizationPlayerId);
        expect(refunded.wonderType, WonderType.greatLibrary);
        expect(refunded.refundedProduction, wonderCost);
        expectRushSliceIdentities(
          state,
          result.state,
          citiesSame: false,
          unitsSame: null,
          playerGoldSame: false,
        );
        expectRushUnitElementsShared(state, result.state);
      },
    );
  });
}

List<RushRejectionCase> _rushPrecedenceRejectionCases() {
  return [
    (
      name: 'city-not-found-precedes-control-queue-project-and-treasury',
      state: rushCharacterizationState(
        cities: rushCharacterizationCities(
          rushCharacterizationCity(
            id: 'other_city',
            ownerPlayerId: rushCharacterizationOtherPlayerId,
            productionQueue: CityProductionQueue.project(
              projectType: CityProjectType.wealth,
            ),
          ),
        ),
        playerGold: const {},
      ),
      command: const RushProductionCommand('missing_city'),
      actorPlayerId: rushCharacterizationOtherPlayerId,
      reason: 'city_not_found',
    ),
    (
      name: 'city-control-precedes-empty-queue-and-treasury',
      state: rushCharacterizationState(
        cities: rushCharacterizationCities(
          rushCharacterizationCity(
            ownerPlayerId: rushCharacterizationOtherPlayerId,
          ),
        ),
        playerGold: const {},
      ),
      command: const RushProductionCommand('city_1'),
      actorPlayerId: rushCharacterizationPlayerId,
      reason: 'city_not_controlled',
    ),
    (
      name: 'empty-queue-precedes-treasury',
      state: rushCharacterizationState(
        cities: rushCharacterizationCities(rushCharacterizationCity()),
        playerGold: const {},
      ),
      command: const RushProductionCommand('city_1'),
      actorPlayerId: rushCharacterizationPlayerId,
      reason: 'production_queue_empty',
    ),
    (
      name: 'continuous-project-precedes-treasury',
      state: rushCharacterizationState(
        cities: rushCharacterizationCities(
          rushCharacterizationCity(
            productionQueue: CityProductionQueue.project(
              projectType: CityProjectType.research,
              investedProduction: 7,
            ),
          ),
        ),
        playerGold: const {},
      ),
      command: const RushProductionCommand('city_1'),
      actorPlayerId: rushCharacterizationPlayerId,
      reason: 'project_cannot_be_rushed',
    ),
  ];
}
