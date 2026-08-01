import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

void main() {
  group('Combat rules', () {
    test('standard ruleset keeps combat variance tunable and wider', () {
      expect(CombatRuleset.standard.varianceRange, 2);
      expect(const CombatRuleset().varianceRange, 2);
      expect(const CombatRuleset(varianceRange: 0).varianceRange, 0);
    });

    test('resolves deterministic melee combat with retaliation', () {
      final outcome = CombatResolver.resolve(
        attacker: _combatant(
          id: 'attacker',
          stats: const CombatStats(attack: 6, defense: 1, hp: 10, range: 1),
        ),
        defender: _combatant(
          id: 'defender',
          owner: 'player_2',
          stats: const CombatStats(attack: 5, defense: 1, hp: 10, range: 1),
        ),
        rng: CombatRng(99),
        attackDistance: 1,
        ruleset: const CombatRuleset(varianceRange: 0),
      );

      expect(outcome.defenderHpAfter, 5);
      expect(outcome.attackerHpAfter, 6);
      expect(outcome.defenderKilled, isFalse);
      expect(outcome.steps.whereType<RetaliationStep>(), hasLength(1));
    });

    test('retaliates against point-blank ranged attacks', () {
      final outcome = CombatResolver.resolve(
        attacker: _combatant(
          id: 'attacker',
          stats: const CombatStats(attack: 6, defense: 1, hp: 10, range: 2),
        ),
        defender: _combatant(
          id: 'defender',
          owner: 'player_2',
          stats: const CombatStats(attack: 5, defense: 1, hp: 10, range: 1),
        ),
        rng: CombatRng(99),
        attackDistance: 1,
        ruleset: const CombatRuleset(varianceRange: 0),
      );

      expect(outcome.defenderHpAfter, 5);
      expect(outcome.attackerHpAfter, 6);
      expect(outcome.steps.whereType<RetaliationStep>(), hasLength(1));
    });

    test('keeps standoff ranged attacks retaliation-free', () {
      final outcome = CombatResolver.resolve(
        attacker: _combatant(
          id: 'attacker',
          stats: const CombatStats(attack: 6, defense: 1, hp: 10, range: 2),
        ),
        defender: _combatant(
          id: 'defender',
          owner: 'player_2',
          stats: const CombatStats(attack: 5, defense: 1, hp: 10, range: 1),
        ),
        rng: CombatRng(99),
        attackDistance: 2,
        ruleset: const CombatRuleset(varianceRange: 0),
      );

      expect(outcome.defenderHpAfter, 5);
      expect(outcome.attackerHpAfter, 10);
      expect(outcome.steps.whereType<RetaliationStep>(), isEmpty);
    });

    test('applies partial counter-battery retaliation', () {
      final outcome = CombatResolver.resolve(
        attacker: _combatant(
          id: 'attacker',
          stats: const CombatStats(attack: 6, defense: 1, hp: 10, range: 2),
        ),
        defender: _combatant(
          id: 'defender',
          owner: 'player_2',
          stats: const CombatStats(attack: 5, defense: 1, hp: 10, range: 2),
        ),
        rng: CombatRng(99),
        attackDistance: 2,
        ruleset: const CombatRuleset(varianceRange: 0),
      );

      expect(outcome.defenderHpAfter, 5);
      expect(outcome.attackerHpAfter, 8);
      expect(outcome.steps.whereType<RetaliationStep>().single.damage, 2);
    });

    test('clamps shared ranged retaliation tuning', () {
      expect(
        CombatRetaliationRules.percentFor(
          attackDistance: 1,
          defenderRange: 1,
          ruleset: const CombatRuleset(rangedRetaliationPercent: 50),
        ),
        100,
      );
      expect(
        CombatRetaliationRules.percentFor(
          attackDistance: 2,
          defenderRange: 1,
          ruleset: const CombatRuleset(rangedRetaliationPercent: 50),
        ),
        0,
      );
      expect(
        CombatRetaliationRules.percentFor(
          attackDistance: 2,
          defenderRange: 2,
          ruleset: const CombatRuleset(rangedRetaliationPercent: -10),
        ),
        0,
      );
      expect(
        CombatRetaliationRules.percentFor(
          attackDistance: 2,
          defenderRange: 2,
          ruleset: const CombatRuleset(rangedRetaliationPercent: 150),
        ),
        100,
      );
    });

    test('copyWith can tune combat variance and ranged retaliation', () {
      final copy = CombatRuleset.standard.copyWith(
        varianceRange: 0,
        rangedRetaliationPercent: 25,
      );

      expect(copy.varianceRange, 0);
      expect(copy.rangedRetaliationPercent, 25);
      expect(
        copy.retreatThresholdPercent,
        CombatRuleset.standard.retreatThresholdPercent,
      );
    });

    test('lethal damage kills instead of forcing retreat', () {
      final outcome = CombatResolver.resolve(
        attacker: _combatant(
          id: 'attacker',
          stats: const CombatStats(attack: 9, defense: 1, hp: 10),
        ),
        defender: _combatant(
          id: 'defender',
          owner: 'player_2',
          stats: const CombatStats(attack: 5, defense: 0, hp: 8, mobility: 1),
        ),
        rng: CombatRng(99),
        attackDistance: 1,
        ruleset: const CombatRuleset(
          varianceRange: 0,
          retreatThresholdPercent: 25,
        ),
        defenderCanRetreat: true,
      );

      expect(outcome.defenderKilled, isTrue);
      expect(outcome.defenderRetreated, isFalse);
      expect(outcome.defenderHpAfter, lessThanOrEqualTo(0));
    });

    test('serializes combat outcome with steps and modifiers', () {
      final outcome = CombatOutcome(
        attackerUnitId: 'attacker',
        defenderUnitId: 'defender',
        attackerHpAfter: 7,
        defenderHpAfter: 0,
        attackerKilled: false,
        defenderKilled: true,
        steps: [
          const ModifierAppliedStep(
            TerrainModifier(
              label: 'terrain.forest',
              target: CombatStatTarget.defense,
              delta: 1,
            ),
          ),
          const ModifierAppliedStep(
            VeterancyModifier(
              label: 'veterancy.veteran.defense',
              target: CombatStatTarget.defense,
              delta: 1,
            ),
          ),
          const ModifierAppliedStep(
            CounterModifier(
              label: 'counter.spearmanVsMounted.attack',
              target: CombatStatTarget.attack,
              delta: 2,
            ),
          ),
          AttackStep(
            damage: 6,
            active: const [
              TechnologyModifier(
                label: 'tech.strategy',
                target: CombatStatTarget.attack,
                delta: 1,
              ),
            ],
          ),
          const RollStep(seed: 42, value: -1),
        ],
      );

      final restored = CombatOutcomeSerializer.fromJson(
        CombatOutcomeSerializer.toJson(outcome),
      );

      expect(restored, outcome);
      expect(
        restored.steps.whereType<ModifierAppliedStep>().first.modifier,
        isA<TerrainModifier>(),
      );
      expect(
        restored.steps.whereType<ModifierAppliedStep>().map(
          (step) => step.modifier,
        ),
        contains(isA<VeterancyModifier>()),
      );
      expect(
        restored.steps.whereType<ModifierAppliedStep>().map(
          (step) => step.modifier,
        ),
        contains(isA<CounterModifier>()),
      );
    });

    test('collects terrain, technology, and city defense modifiers', () {
      final modifiers = CombatModifierCollector.forDefender(
        unit: _unit(),
        tile: _tile(terrains: const [TerrainType.forest, TerrainType.hills]),
        defendedCity: const GameCity(
          id: 'city_1',
          ownerPlayerId: 'player_1',
          name: 'Roma',
          center: CityHex(col: 1, row: 1),
        ),
        research: PlayerResearchState(
          unlockedTechnologyIds: {TechnologyId.fortifications},
        ),
      );

      expect(
        modifiers,
        containsAll(const [
          TerrainModifier(
            label: 'terrain.forest.defense',
            target: CombatStatTarget.defense,
            delta: 1,
          ),
          FortificationModifier(
            label: 'city.city_1.garrison',
            target: CombatStatTarget.defense,
            delta: 1,
          ),
          TechnologyModifier(
            label: 'tech.fortifications.cityDefense',
            target: CombatStatTarget.defense,
            delta: 2,
          ),
        ]),
      );
    });

    test('scales effective combat stats through military technologies', () {
      final unit = _unit();
      final modifiers = CombatModifierCollector.forAttacker(
        unit: unit,
        tile: _tile(),
        research: PlayerResearchState(
          unlockedTechnologyIds: {
            TechnologyId.militaryOrganization,
            TechnologyId.tactics,
            TechnologyId.strategy,
          },
        ),
      );

      expect(
        UnitCombatStats.derive(unit).applyAll(modifiers),
        const CombatStats(attack: 6, defense: 5, hp: 13, range: 1, mobility: 1),
      );
    });

    test('collects unit counter modifiers for key matchups', () {
      final spearman = _unit(type: GameUnitType.spearman);
      final cavalry = _unit(type: GameUnitType.cavalry);

      final attackerModifiers = CombatModifierCollector.forAttacker(
        unit: spearman,
        tile: _tile(),
        research: PlayerResearchState.empty,
        defender: cavalry,
        defenderTile: _tile(),
      );
      final defenderModifiers = CombatModifierCollector.forDefender(
        unit: spearman,
        tile: _tile(),
        defendedCity: null,
        research: PlayerResearchState.empty,
        attacker: cavalry,
      );

      expect(
        attackerModifiers,
        contains(
          const CounterModifier(
            label: 'counter.spearmanVsMounted.attack',
            target: CombatStatTarget.attack,
            delta: 2,
          ),
        ),
      );
      expect(
        defenderModifiers,
        contains(
          const CounterModifier(
            label: 'counter.spearmanVsMounted.defense',
            target: CombatStatTarget.defense,
            delta: 3,
          ),
        ),
      );
    });

    test('collects terrain-sensitive archer and cavalry counter modifiers', () {
      final archer = _unit(type: GameUnitType.archer);
      final cavalry = _unit(type: GameUnitType.cavalry);
      final warrior = _unit(type: GameUnitType.warrior);
      final hill = _tile(terrains: const [TerrainType.hills]);

      final archerModifiers = CombatModifierCollector.forDefender(
        unit: archer,
        tile: hill,
        defendedCity: null,
        research: PlayerResearchState.empty,
        attacker: warrior,
      );
      final cavalryModifiers = CombatModifierCollector.forAttacker(
        unit: cavalry,
        tile: _tile(),
        research: PlayerResearchState.empty,
        defender: archer,
        defenderTile: hill,
      );

      expect(
        archerModifiers,
        contains(
          const CounterModifier(
            label: 'counter.archerDefensiveTerrain.defense',
            target: CombatStatTarget.defense,
            delta: 2,
          ),
        ),
      );
      expect(
        cavalryModifiers,
        contains(
          const CounterModifier(
            label: 'counter.cavalryRoughAttack.attack',
            target: CombatStatTarget.attack,
            delta: -2,
          ),
        ),
      );
    });

    test('collects heavy infantry breakthrough counter modifier', () {
      final heavyInfantry = _unit(type: GameUnitType.heavyInfantry);
      final spearman = _unit(type: GameUnitType.spearman);

      final modifiers = CombatModifierCollector.forAttacker(
        unit: heavyInfantry,
        tile: _tile(),
        research: PlayerResearchState.empty,
        defender: spearman,
        defenderTile: _tile(),
      );

      expect(
        modifiers,
        contains(
          const CounterModifier(
            label: 'counter.heavyInfantryBreakthrough.attack',
            target: CombatStatTarget.attack,
            delta: 2,
          ),
        ),
      );
    });

    test('derives commander stats from army composition', () {
      final commander = GameUnit.startingCommander(
        ownerPlayerId: 'player_1',
        army: const [
          ArmyTroop(type: TroopType.warrior, count: 2),
          ArmyTroop(type: TroopType.archer, count: 1),
        ],
      );

      expect(
        UnitCombatStats.derive(commander),
        const CombatStats(attack: 7, defense: 6, hp: 16, range: 1, mobility: 2),
      );
    });
  });
}

Combatant _combatant({
  required String id,
  String owner = 'player_1',
  required CombatStats stats,
}) {
  return Combatant(unitId: id, ownerPlayerId: owner, baseStats: stats);
}

GameUnit _unit({GameUnitType type = GameUnitType.warrior}) {
  return GameUnit(
    id: '${type.name}_1',
    ownerPlayerId: 'player_1',
    type: type,
    name: type.defaultNameToken,
    col: 1,
    row: 1,
  );
}

WorldTile _tile({List<TerrainType> terrains = const [TerrainType.grassland]}) {
  return WorldTile(
    col: 1,
    row: 1,
    terrains: terrains,
    resources: const [],
    height: 0,
  );
}
