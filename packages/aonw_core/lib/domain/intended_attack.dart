import 'package:aonw_core/game/domain/combat/city_conquest_action.dart';
import 'package:aonw_core/util/wire_json.dart';

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
    final reader = WireJson(json, 'IntendedAttack');
    return IntendedAttack(
      attackerUnitId: reader.requiredString('attackerUnitId'),
      defenderCol: reader.requiredInt('defenderCol'),
      defenderRow: reader.requiredInt('defenderRow'),
      declaredAtTick: reader.requiredInt('declaredAtTick'),
      declaringPlayerId: reader.requiredString('declaringPlayerId'),
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

  static CityConquestAction _cityConquestAction(Object? value) {
    return optionalEnumByName(
          value,
          CityConquestAction.values,
          'IntendedAttack.cityConquestAction',
        ) ??
        CityConquestAction.capture;
  }
}
