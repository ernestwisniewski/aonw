import 'package:aonw_core/game/domain/combat/combat_modifier.dart';
import 'package:aonw_core/game/domain/combat/combat_outcome.dart';
import 'package:aonw_core/game/domain/combat/combat_step.dart';
import 'package:aonw_core/util/wire_json.dart';

abstract final class CombatOutcomeSerializer {
  static Map<String, dynamic> toJson(CombatOutcome outcome) => {
    'attackerUnitId': outcome.attackerUnitId,
    'defenderUnitId': outcome.defenderUnitId,
    'attackerHpAfter': outcome.attackerHpAfter,
    'defenderHpAfter': outcome.defenderHpAfter,
    'attackerKilled': outcome.attackerKilled,
    'defenderKilled': outcome.defenderKilled,
    'defenderRetreated': outcome.defenderRetreated,
    'steps': [for (final step in outcome.steps) _stepToJson(step)],
  };

  static CombatOutcome fromJson(Map<String, dynamic> json) {
    return CombatOutcome(
      attackerUnitId: requiredStringField(
        json,
        'CombatOutcome',
        'attackerUnitId',
      ),
      defenderUnitId: requiredStringField(
        json,
        'CombatOutcome',
        'defenderUnitId',
      ),
      attackerHpAfter: requiredIntField(
        json,
        'CombatOutcome',
        'attackerHpAfter',
      ),
      defenderHpAfter: requiredIntField(
        json,
        'CombatOutcome',
        'defenderHpAfter',
      ),
      attackerKilled: requiredBoolField(
        json,
        'CombatOutcome',
        'attackerKilled',
      ),
      defenderKilled: requiredBoolField(
        json,
        'CombatOutcome',
        'defenderKilled',
      ),
      defenderRetreated: requiredBoolField(
        json,
        'CombatOutcome',
        'defenderRetreated',
      ),
      steps: [
        for (final step in requiredListField(json, 'CombatOutcome', 'steps'))
          _stepFromJson(requiredMapValue(step, 'CombatOutcome.steps[]')),
      ],
    );
  }

  static Map<String, dynamic> _stepToJson(CombatStep step) => switch (step) {
    AttackStep(:final damage, :final active) => {
      'type': 'Attack',
      'damage': damage,
      'active': [for (final modifier in active) _modifierToJson(modifier)],
    },
    RetaliationStep(:final damage, :final active) => {
      'type': 'Retaliation',
      'damage': damage,
      'active': [for (final modifier in active) _modifierToJson(modifier)],
    },
    ModifierAppliedStep(:final modifier) => {
      'type': 'ModifierApplied',
      'modifier': _modifierToJson(modifier),
    },
    RollStep(:final seed, :final value) => {
      'type': 'Roll',
      'seed': seed,
      'value': value,
    },
  };

  static CombatStep _stepFromJson(Map<String, dynamic> json) {
    final type = requiredStringField(json, 'CombatStep', 'type');
    return switch (type) {
      'Attack' => AttackStep(
        damage: requiredIntField(json, type, 'damage'),
        active: [
          for (final modifier in requiredListField(json, type, 'active'))
            _modifierFromJson(requiredMapValue(modifier, '$type.active[]')),
        ],
      ),
      'Retaliation' => RetaliationStep(
        damage: requiredIntField(json, type, 'damage'),
        active: [
          for (final modifier in requiredListField(json, type, 'active'))
            _modifierFromJson(requiredMapValue(modifier, '$type.active[]')),
        ],
      ),
      'ModifierApplied' => ModifierAppliedStep(
        _modifierFromJson(requiredMapValue(json['modifier'], '$type.modifier')),
      ),
      'Roll' => RollStep(
        seed: requiredIntField(json, type, 'seed'),
        value: requiredIntField(json, type, 'value'),
      ),
      _ => throw ArgumentError('Unknown CombatStep type: $type'),
    };
  }

  static Map<String, dynamic> _modifierToJson(CombatModifier modifier) => {
    'type': switch (modifier) {
      TerrainModifier() => 'Terrain',
      FortificationModifier() => 'Fortification',
      TechnologyModifier() => 'Technology',
      CounterModifier() => 'Counter',
      TroopCompositionModifier() => 'TroopComposition',
      VeterancyModifier() => 'Veterancy',
    },
    'label': modifier.label,
    'target': modifier.target.name,
    'delta': modifier.delta,
  };

  static CombatModifier _modifierFromJson(Map<String, dynamic> json) {
    final type = requiredStringField(json, 'CombatModifier', 'type');
    final label = requiredStringField(json, type, 'label');
    final target = requiredEnumField(
      json,
      type,
      'target',
      CombatStatTarget.values,
    );
    final delta = requiredIntField(json, type, 'delta');
    return switch (type) {
      'Terrain' => TerrainModifier(label: label, target: target, delta: delta),
      'Fortification' => FortificationModifier(
        label: label,
        target: target,
        delta: delta,
      ),
      'Technology' => TechnologyModifier(
        label: label,
        target: target,
        delta: delta,
      ),
      'Counter' => CounterModifier(label: label, target: target, delta: delta),
      'TroopComposition' => TroopCompositionModifier(
        label: label,
        target: target,
        delta: delta,
      ),
      'Veterancy' => VeterancyModifier(
        label: label,
        target: target,
        delta: delta,
      ),
      _ => throw ArgumentError('Unknown CombatModifier type: $type'),
    };
  }
}
