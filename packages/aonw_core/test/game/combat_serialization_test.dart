import 'package:aonw_core/game/domain/combat.dart';
import 'package:test/test.dart';

void main() {
  group('CombatOutcomeSerializer', () {
    test('round-trips the exact wire shape for every step and modifier', () {
      final outcome = _completeOutcome();

      final json = CombatOutcomeSerializer.toJson(outcome);
      final restored = CombatOutcomeSerializer.fromJson(json);

      expect(json, _completeJson());
      expect(restored, outcome);

      final attack = restored.steps[0] as AttackStep;
      final retaliation = restored.steps[1] as RetaliationStep;
      final applied = restored.steps[2] as ModifierAppliedStep;
      expect(restored.steps[3], isA<RollStep>());
      expect(
        [
          ...attack.active,
          ...retaliation.active,
          applied.modifier,
        ].map((modifier) => modifier.runtimeType),
        [
          TerrainModifier,
          FortificationModifier,
          TechnologyModifier,
          CounterModifier,
          TroopCompositionModifier,
          VeterancyModifier,
        ],
      );
    });

    test('rejects unknown step discriminators', () {
      final json = _completeJson()
        ..['steps'] = const [
          {'type': 'UnknownStep'},
        ];

      expect(
        () => CombatOutcomeSerializer.fromJson(json),
        throwsA(
          isA<ArgumentError>().having(
            (error) => error.message,
            'message',
            contains('Unknown CombatStep type: UnknownStep'),
          ),
        ),
      );
    });

    test('rejects unknown modifier discriminators', () {
      final json = _completeJson()
        ..['steps'] = const [
          {
            'type': 'ModifierApplied',
            'modifier': {
              'type': 'UnknownModifier',
              'label': 'unknown',
              'target': 'attack',
              'delta': 0,
            },
          },
        ];

      expect(
        () => CombatOutcomeSerializer.fromJson(json),
        throwsA(
          isA<ArgumentError>().having(
            (error) => error.message,
            'message',
            contains('Unknown CombatModifier type: UnknownModifier'),
          ),
        ),
      );
    });

    test('reports malformed nested collections with their wire field', () {
      final json = _completeJson()
        ..['steps'] = const [
          {'type': 'Attack', 'damage': 7, 'active': 'not-a-list'},
        ];

      expect(
        () => CombatOutcomeSerializer.fromJson(json),
        throwsA(
          isA<ArgumentError>().having(
            (error) => error.name,
            'name',
            'Attack.active',
          ),
        ),
      );
    });
  });
}

CombatOutcome _completeOutcome() {
  return CombatOutcome(
    attackerUnitId: 'attacker',
    defenderUnitId: 'defender',
    attackerHpAfter: 0,
    defenderHpAfter: 4,
    attackerKilled: true,
    defenderKilled: false,
    defenderRetreated: true,
    steps: [
      AttackStep(
        damage: 7,
        active: const [
          TerrainModifier(
            label: 'terrain.hills',
            target: CombatStatTarget.defense,
            delta: 2,
          ),
          FortificationModifier(
            label: 'fortification.city',
            target: CombatStatTarget.hp,
            delta: 3,
          ),
        ],
      ),
      RetaliationStep(
        damage: 3,
        active: const [
          TechnologyModifier(
            label: 'technology.ballistics',
            target: CombatStatTarget.attack,
            delta: 4,
          ),
          CounterModifier(
            label: 'counter.archer',
            target: CombatStatTarget.range,
            delta: -2,
          ),
          TroopCompositionModifier(
            label: 'troops.combined',
            target: CombatStatTarget.mobility,
            delta: 5,
          ),
        ],
      ),
      const ModifierAppliedStep(
        VeterancyModifier(
          label: 'veterancy.elite',
          target: CombatStatTarget.defense,
          delta: 1,
        ),
      ),
      const RollStep(seed: 42, value: -1),
    ],
  );
}

Map<String, dynamic> _completeJson() {
  return {
    'attackerUnitId': 'attacker',
    'defenderUnitId': 'defender',
    'attackerHpAfter': 0,
    'defenderHpAfter': 4,
    'attackerKilled': true,
    'defenderKilled': false,
    'defenderRetreated': true,
    'steps': [
      {
        'type': 'Attack',
        'damage': 7,
        'active': [
          {
            'type': 'Terrain',
            'label': 'terrain.hills',
            'target': 'defense',
            'delta': 2,
          },
          {
            'type': 'Fortification',
            'label': 'fortification.city',
            'target': 'hp',
            'delta': 3,
          },
        ],
      },
      {
        'type': 'Retaliation',
        'damage': 3,
        'active': [
          {
            'type': 'Technology',
            'label': 'technology.ballistics',
            'target': 'attack',
            'delta': 4,
          },
          {
            'type': 'Counter',
            'label': 'counter.archer',
            'target': 'range',
            'delta': -2,
          },
          {
            'type': 'TroopComposition',
            'label': 'troops.combined',
            'target': 'mobility',
            'delta': 5,
          },
        ],
      },
      {
        'type': 'ModifierApplied',
        'modifier': {
          'type': 'Veterancy',
          'label': 'veterancy.elite',
          'target': 'defense',
          'delta': 1,
        },
      },
      {'type': 'Roll', 'seed': 42, 'value': -1},
    ],
  };
}
