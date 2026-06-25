import 'package:aonw_core/game/domain/combat/combat_modifier.dart';
import 'package:aonw_core/game/domain/combat/combat_outcome.dart';
import 'package:aonw_core/game/domain/combat/combat_step.dart';

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
      attackerUnitId: _requiredString(json, 'CombatOutcome', 'attackerUnitId'),
      defenderUnitId: _requiredString(json, 'CombatOutcome', 'defenderUnitId'),
      attackerHpAfter: _requiredInt(json, 'CombatOutcome', 'attackerHpAfter'),
      defenderHpAfter: _requiredInt(json, 'CombatOutcome', 'defenderHpAfter'),
      attackerKilled: _requiredBool(json, 'CombatOutcome', 'attackerKilled'),
      defenderKilled: _requiredBool(json, 'CombatOutcome', 'defenderKilled'),
      defenderRetreated: _requiredBool(
        json,
        'CombatOutcome',
        'defenderRetreated',
      ),
      steps: [
        for (final step in _requiredList(json, 'CombatOutcome', 'steps'))
          _stepFromJson(_requiredMap(step, 'CombatOutcome.steps[]')),
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
    final type = _requiredString(json, 'CombatStep', 'type');
    return switch (type) {
      'Attack' => AttackStep(
        damage: _requiredInt(json, type, 'damage'),
        active: [
          for (final modifier in _requiredList(json, type, 'active'))
            _modifierFromJson(_requiredMap(modifier, '$type.active[]')),
        ],
      ),
      'Retaliation' => RetaliationStep(
        damage: _requiredInt(json, type, 'damage'),
        active: [
          for (final modifier in _requiredList(json, type, 'active'))
            _modifierFromJson(_requiredMap(modifier, '$type.active[]')),
        ],
      ),
      'ModifierApplied' => ModifierAppliedStep(
        _modifierFromJson(_requiredMap(json['modifier'], '$type.modifier')),
      ),
      'Roll' => RollStep(
        seed: _requiredInt(json, type, 'seed'),
        value: _requiredInt(json, type, 'value'),
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
    final type = _requiredString(json, 'CombatModifier', 'type');
    final label = _requiredString(json, type, 'label');
    final target = _requiredEnum(json, type, 'target', CombatStatTarget.values);
    final delta = _requiredInt(json, type, 'delta');
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

  static String _requiredString(
    Map<String, dynamic> json,
    String type,
    String field,
  ) {
    final value = json[field];
    if (value is String && value.isNotEmpty) return value;
    throw ArgumentError.value(
      value,
      '$type.$field',
      'Expected a non-empty String',
    );
  }

  static int _requiredInt(
    Map<String, dynamic> json,
    String type,
    String field,
  ) {
    final value = json[field];
    if (value is int) return value;
    throw ArgumentError.value(value, '$type.$field', 'Expected an int');
  }

  static bool _requiredBool(
    Map<String, dynamic> json,
    String type,
    String field,
  ) {
    final value = json[field];
    if (value is bool) return value;
    throw ArgumentError.value(value, '$type.$field', 'Expected a bool');
  }

  static List<dynamic> _requiredList(
    Map<String, dynamic> json,
    String type,
    String field,
  ) {
    final value = json[field];
    if (value is List) return value;
    throw ArgumentError.value(value, '$type.$field', 'Expected a List');
  }

  static Map<String, dynamic> _requiredMap(Object? value, String name) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    throw ArgumentError.value(value, name, 'Expected a JSON object');
  }

  static T _requiredEnum<T extends Enum>(
    Map<String, dynamic> json,
    String type,
    String field,
    Iterable<T> values,
  ) {
    final name = _requiredString(json, type, field);
    for (final value in values) {
      if (value.name == name) return value;
    }
    throw ArgumentError.value(name, '$type.$field', 'Unknown value');
  }
}
