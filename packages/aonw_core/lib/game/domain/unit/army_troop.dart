import 'package:aonw_core/game/domain/unit/game_unit_type.dart';

enum TroopType {
  warrior,
  archer,
  settler;

  GameUnitType get detachedUnitType {
    return switch (this) {
      TroopType.warrior => GameUnitType.warrior,
      TroopType.archer => GameUnitType.archer,
      TroopType.settler => GameUnitType.settler,
    };
  }

  String get detachedUnitNameToken {
    return detachedUnitType.defaultNameToken;
  }
}

class ArmyTroop {
  final TroopType type;
  final int count;

  const ArmyTroop({required this.type, required this.count});

  factory ArmyTroop.fromJson(Map<String, dynamic> json) {
    return ArmyTroop(
      type: TroopType.values.byName(json['type'] as String),
      count: (json['count'] as num).toInt(),
    );
  }

  Map<String, dynamic> toJson() => {'type': type.name, 'count': count};

  @override
  bool operator ==(Object other) =>
      other is ArmyTroop && other.type == type && other.count == count;

  @override
  int get hashCode => Object.hash(type, count);
}
