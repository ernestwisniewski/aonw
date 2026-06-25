import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

void main() {
  group('Technology rules', () {
    const ruleset = TechnologyRulesets.standard;

    test('defines every technology once with known prerequisites', () {
      expect(ruleset.technologies, hasLength(TechnologyId.values.length));
      expect(ruleset.technologies.keys.toSet(), TechnologyId.values.toSet());

      for (final entry in ruleset.technologies.entries) {
        expect(entry.value.id, entry.key);
        for (final prerequisite in entry.value.prerequisites) {
          expect(ruleset.technologies, contains(prerequisite));
        }
        for (final blocker in entry.value.blockedBy) {
          expect(ruleset.technologies, contains(blocker));
        }
      }
    });

    test('keeps core unlock mappings stable', () {
      expect(
        ruleset.definitionFor(TechnologyId.agriculture).unlocks,
        contains(const UnlockFieldImprovement(FieldImprovementType.farm)),
      );
      expect(
        ruleset.definitionFor(TechnologyId.agriculture).unlocks,
        contains(const UnlockFieldImprovement(FieldImprovementType.orchard)),
      );
      expect(
        ruleset.definitionFor(TechnologyId.trade).unlocks,
        contains(
          const UnlockFieldImprovement(FieldImprovementType.tradingPost),
        ),
      );
      expect(
        ruleset.definitionFor(TechnologyId.trade).unlocks,
        contains(const UnlockUnitType(GameUnitType.merchant)),
      );
      expect(
        ruleset.definitionFor(TechnologyId.advancedTrade).unlocks,
        contains(const UnlockFieldImprovement(FieldImprovementType.plantation)),
      );
      expect(
        ruleset.definitionFor(TechnologyId.navigation).unlocks,
        contains(
          const UnlockFieldImprovement(FieldImprovementType.pearlDivers),
        ),
      );
      expect(
        ruleset.definitionFor(TechnologyId.hunting).unlocks,
        contains(const UnlockUnitType(GameUnitType.archer)),
      );
      expect(
        ruleset.definitionFor(TechnologyId.strategy).unlocks,
        contains(const UnlockUnitType(GameUnitType.commander)),
      );
      expect(
        TechnologyUnlockQuery.unlockingTechnologyForBuilding(
          buildingType: CityBuildingType.marketplace,
          ruleset: ruleset,
        )?.id,
        TechnologyId.advancedTrade,
      );
    });

    test('unlocks every standard field improvement through the tech tree', () {
      for (final improvement in FieldImprovementType.values) {
        expect(
          TechnologyUnlockQuery.unlockingTechnologyForFieldImprovement(
            improvementType: improvement,
            ruleset: ruleset,
          ),
          isNotNull,
          reason: '${improvement.name} should be unlocked by a technology',
        );
      }
    });

    test('reports availability from player research state', () {
      final playerResearch = PlayerResearchState(
        unlockedTechnologyIds: {TechnologyId.agriculture},
        activeTechnologyId: TechnologyId.mining,
      );

      expect(
        TechnologyAvailabilityService.availabilityFor(
          technologyId: TechnologyId.agriculture,
          playerResearch: playerResearch,
          ruleset: ruleset,
        ),
        TechnologyAvailability.unlocked,
      );
      expect(
        TechnologyAvailabilityService.availabilityFor(
          technologyId: TechnologyId.mining,
          playerResearch: playerResearch,
          ruleset: ruleset,
        ),
        TechnologyAvailability.active,
      );
      expect(
        TechnologyAvailabilityService.availabilityFor(
          technologyId: TechnologyId.trade,
          playerResearch: playerResearch,
          ruleset: ruleset,
        ),
        TechnologyAvailability.available,
      );
      expect(
        TechnologyAvailabilityService.availabilityFor(
          technologyId: TechnologyId.banking,
          playerResearch: playerResearch,
          ruleset: ruleset,
        ),
        TechnologyAvailability.lockedByPrerequisites,
      );
    });

    test('reports technologies blocked by unlocked technologies', () {
      final ruleset = _rulesetWithTradeBlockedByMining();

      expect(
        TechnologyAvailabilityService.availabilityFor(
          technologyId: TechnologyId.trade,
          playerResearch: PlayerResearchState(
            unlockedTechnologyIds: {TechnologyId.agriculture},
          ),
          ruleset: ruleset,
        ),
        TechnologyAvailability.available,
      );
      expect(
        TechnologyAvailabilityService.availabilityFor(
          technologyId: TechnologyId.trade,
          playerResearch: PlayerResearchState(
            unlockedTechnologyIds: {
              TechnologyId.agriculture,
              TechnologyId.mining,
            },
          ),
          ruleset: ruleset,
        ),
        TechnologyAvailability.lockedByTechnology,
      );
    });

    test('aggregates effects and applies research costs', () {
      final research = ResearchState(
        players: {
          'player_1': PlayerResearchState(
            unlockedTechnologyIds: {
              TechnologyId.ironWorking,
              TechnologyId.economy,
              TechnologyId.fortifications,
              TechnologyId.strategy,
              TechnologyId.specialization,
            },
          ),
        },
      );

      final summary = TechnologyEffectSummary.forPlayer(
        playerId: 'player_1',
        research: research,
        ruleset: ruleset,
      );

      expect(summary.strategicResourceProductionByType[ResourceType.iron], 1);
      expect(summary.globalGoldMultiplier, 0.10);
      expect(summary.cityDefenseBonus, 2);
      expect(summary.armyStrengthMultiplier, 0.10);
      expect(summary.armyAttackBonus, 0);
      expect(summary.armyDefenseBonus, 1);
      expect(summary.armyHitPointsBonus, 2);
      expect(summary.cityScienceBonus, 1);
      expect(
        ResearchCostCalculator.effectiveCost(
          technology: ruleset.definitionFor(TechnologyId.strategy),
          cityCount: 2,
          ruleset: ruleset,
        ),
        124,
      );
      expect(
        ResearchCostCalculator.effectiveCost(
          technology: ruleset.definitionFor(TechnologyId.strategy),
          cityCount: 2,
          ruleset: ruleset,
          paceBalance: PaceBalance.standard60,
        ),
        100,
      );
      expect(
        ResearchCostCalculator.effectiveCost(
          technology: ruleset.definitionFor(TechnologyId.education),
          cityCount: 2,
          ruleset: ruleset,
        ),
        37,
      );
      expect(
        ResearchCostCalculator.effectiveCost(
          technology: ruleset.definitionFor(TechnologyId.steel),
          cityCount: 2,
          ruleset: ruleset,
        ),
        62,
      );
    });

    test('advances active research with satisfied resource boosts', () {
      const city = GameCity(
        id: 'city_1',
        ownerPlayerId: 'player_1',
        name: 'City',
        center: CityHex(col: 0, row: 0),
        controlledHexes: [CityHex(col: 1, row: 0)],
      );
      final research = ResearchState(
        players: {
          'player_1': PlayerResearchState(
            activeTechnologyId: TechnologyId.agriculture,
            progressByTechnologyId: {TechnologyId.agriculture: 3},
          ),
        },
      );

      final result = ResearchTurnProcessor.advanceForPlayer(
        playerId: 'player_1',
        cities: [city],
        fieldImprovements: const [],
        research: research,
        mapData: _map(
          resourcesByCol: {
            1: {ResourceType.wheat},
          },
        ),
      );

      expect(result.scienceYield.total, 2);
      expect(result.completedTechnologyId, TechnologyId.agriculture);
      expect(
        result.research
            .forPlayer('player_1')
            .hasUnlocked(TechnologyId.agriculture),
        isTrue,
      );
    });

    test('does not advance active research blocked by unlocked technology', () {
      const city = GameCity(
        id: 'city_1',
        ownerPlayerId: 'player_1',
        name: 'City',
        center: CityHex(col: 0, row: 0),
      );
      final research = ResearchState(
        players: {
          'player_1': PlayerResearchState(
            unlockedTechnologyIds: {
              TechnologyId.agriculture,
              TechnologyId.mining,
            },
            activeTechnologyId: TechnologyId.trade,
            progressByTechnologyId: {TechnologyId.trade: 2},
          ),
        },
      );

      final result = ResearchTurnProcessor.advanceForPlayer(
        playerId: 'player_1',
        cities: [city],
        fieldImprovements: const [],
        research: research,
        mapData: _map(),
        ruleset: _rulesetWithTradeBlockedByMining(),
      );

      final playerResearch = result.research.forPlayer('player_1');
      expect(result.changed, isTrue);
      expect(result.completedTechnologyId, isNull);
      expect(playerResearch.activeTechnologyId, isNull);
      expect(playerResearch.progressFor(TechnologyId.trade), 2);
      expect(playerResearch.hasUnlocked(TechnologyId.trade), isFalse);
    });
  });
}

TechnologyRuleset _rulesetWithTradeBlockedByMining() {
  return TechnologyRuleset(
    science: TechnologyRulesets.standard.science,
    costs: TechnologyRulesets.standard.costs,
    technologies: {
      TechnologyId.agriculture: TechnologyRulesets.standard.definitionFor(
        TechnologyId.agriculture,
      ),
      TechnologyId.mining: TechnologyRulesets.standard.definitionFor(
        TechnologyId.mining,
      ),
      TechnologyId.trade: const TechnologyDefinition(
        id: TechnologyId.trade,
        name: 'Trade',
        description: 'Blocked test trade.',
        era: TechnologyEra.settlement,
        baseCost: 7,
        prerequisites: [TechnologyId.agriculture],
        blockedBy: [TechnologyId.mining],
        treePosition: TechnologyTreePosition(column: 1, row: 1),
      ),
    },
  );
}

MapData _map({Map<int, Set<ResourceType>> resourcesByCol = const {}}) {
  return MapData(
    cols: 3,
    rows: 1,
    tiles: [
      for (var col = 0; col < 3; col++)
        TileData(
          col: col,
          row: 0,
          terrains: const [TerrainType.plains],
          resources: resourcesByCol[col]?.toList() ?? const [],
          height: 0,
        ),
    ],
  );
}
