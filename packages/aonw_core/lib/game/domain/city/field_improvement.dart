import 'package:aonw_core/game/domain/city/city_hex.dart';
import 'package:aonw_core/game/domain/city/field_improvement_type.dart';

class FieldImprovement {
  final CityHex hex;
  final FieldImprovementType type;
  final String? builtByCityId;

  const FieldImprovement({
    required this.hex,
    required this.type,
    this.builtByCityId,
  });

  factory FieldImprovement.fromJson(Map<String, dynamic> json) {
    return FieldImprovement(
      hex: CityHex.fromJson(json['hex'] as Map<String, dynamic>),
      type: FieldImprovementType.fromString(json['type'] as String),
      builtByCityId: json['builtByCityId'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'hex': hex.toJson(),
    'type': type.name,
    if (builtByCityId != null) 'builtByCityId': builtByCityId,
  };

  bool occupies(int col, int row) => hex.occupies(col, row);

  @override
  bool operator ==(Object other) =>
      other is FieldImprovement &&
      other.hex == hex &&
      other.type == type &&
      other.builtByCityId == builtByCityId;

  @override
  int get hashCode => Object.hash(hex, type, builtByCityId);
}
