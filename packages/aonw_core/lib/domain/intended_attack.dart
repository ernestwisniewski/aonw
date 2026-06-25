import 'package:aonw_core/game/domain/combat/city_conquest_action.dart';

final class IntendedAttack {
  const IntendedAttack({
    required this.attackerUnitId,
    required this.defenderCol,
    required this.defenderRow,
    required this.declaredAtTick,
    required this.declaringPlayerId,
    this.cityConquestAction = CityConquestAction.capture,
  });

  factory IntendedAttack.fromJson(Map<String, dynamic> json) {
    return IntendedAttack(
      attackerUnitId: _requiredString(json, 'attackerUnitId'),
      defenderCol: _requiredInt(json, 'defenderCol'),
      defenderRow: _requiredInt(json, 'defenderRow'),
      declaredAtTick: _requiredInt(json, 'declaredAtTick'),
      declaringPlayerId: _requiredString(json, 'declaringPlayerId'),
      cityConquestAction: _cityConquestAction(json['cityConquestAction']),
    );
  }

  final String attackerUnitId;
  final int defenderCol;
  final int defenderRow;
  final int declaredAtTick;
  final String declaringPlayerId;
  final CityConquestAction cityConquestAction;

  Map<String, dynamic> toJson() => {
    'attackerUnitId': attackerUnitId,
    'defenderCol': defenderCol,
    'defenderRow': defenderRow,
    'declaredAtTick': declaredAtTick,
    'declaringPlayerId': declaringPlayerId,
    if (cityConquestAction != CityConquestAction.capture)
      'cityConquestAction': cityConquestAction.name,
  };

  @override
  bool operator ==(Object other) =>
      other is IntendedAttack &&
      other.attackerUnitId == attackerUnitId &&
      other.defenderCol == defenderCol &&
      other.defenderRow == defenderRow &&
      other.declaredAtTick == declaredAtTick &&
      other.declaringPlayerId == declaringPlayerId &&
      other.cityConquestAction == cityConquestAction;

  @override
  int get hashCode => Object.hash(
    IntendedAttack,
    attackerUnitId,
    defenderCol,
    defenderRow,
    declaredAtTick,
    declaringPlayerId,
    cityConquestAction,
  );

  static String _requiredString(Map<String, dynamic> json, String field) {
    final value = json[field];
    if (value is String && value.isNotEmpty) return value;
    throw ArgumentError.value(
      value,
      'IntendedAttack.$field',
      'Expected a non-empty String',
    );
  }

  static int _requiredInt(Map<String, dynamic> json, String field) {
    final value = json[field];
    if (value is int) return value;
    throw ArgumentError.value(
      value,
      'IntendedAttack.$field',
      'Expected an int',
    );
  }

  static CityConquestAction _cityConquestAction(Object? value) {
    if (value == null) return CityConquestAction.capture;
    if (value is String && value.isNotEmpty) {
      for (final action in CityConquestAction.values) {
        if (action.name == value) return action;
      }
    }
    throw ArgumentError.value(
      value,
      'IntendedAttack.cityConquestAction',
      'Expected a known CityConquestAction name',
    );
  }
}
