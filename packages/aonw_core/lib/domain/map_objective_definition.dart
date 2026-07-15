import 'package:aonw_core/domain/hex_coord.dart';

enum MapObjectiveType {
  ruins,
  strategicPass,
  holySite,
  legendaryResource;

  static MapObjectiveType fromName(String name) => values.byName(name);
}

/// Immutable objective definition owned by the canonical world model.
final class MapObjectiveDefinition {
  const MapObjectiveDefinition({
    required this.id,
    required this.type,
    required this.hex,
    this.requiredHoldTurns = 3,
    this.victoryPoints = 0,
    this.goldPerTurn = 0,
  });

  factory MapObjectiveDefinition.fromJson(Map<String, dynamic> json) {
    final hex = json['hex'] as Map<String, dynamic>;
    return MapObjectiveDefinition(
      id: json['id'] as String,
      type: MapObjectiveType.fromName(json['type'] as String),
      hex: HexCoord(
        col: (hex['col'] as num).toInt(),
        row: (hex['row'] as num).toInt(),
      ),
      requiredHoldTurns: (json['requiredHoldTurns'] as num?)?.toInt() ?? 3,
      victoryPoints: (json['victoryPoints'] as num?)?.toInt() ?? 0,
      goldPerTurn: (json['goldPerTurn'] as num?)?.toInt() ?? 0,
    );
  }

  final String id;
  final MapObjectiveType type;
  final HexCoord hex;
  final int requiredHoldTurns;
  final int victoryPoints;
  final int goldPerTurn;

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'hex': {'col': hex.col, 'row': hex.row},
    if (requiredHoldTurns != 3) 'requiredHoldTurns': requiredHoldTurns,
    if (victoryPoints != 0) 'victoryPoints': victoryPoints,
    if (goldPerTurn != 0) 'goldPerTurn': goldPerTurn,
  };
}
