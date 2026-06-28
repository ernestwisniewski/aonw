import 'package:aonw_core/game/domain/artifact/world_artifact_type.dart';
import 'package:aonw_core/util/wire_json.dart';

enum WorldArtifactLocationKind { map, carried, stored, excavation }

class WorldArtifactLocation {
  final WorldArtifactLocationKind kind;
  final int? col;
  final int? row;
  final String? unitId;
  final String? cityId;
  final int remainingTurns;

  const WorldArtifactLocation._({
    required this.kind,
    this.col,
    this.row,
    this.unitId,
    this.cityId,
    this.remainingTurns = 0,
  });

  const WorldArtifactLocation.map({required int col, required int row})
    : this._(kind: WorldArtifactLocationKind.map, col: col, row: row);

  const WorldArtifactLocation.carried({required String unitId})
    : this._(kind: WorldArtifactLocationKind.carried, unitId: unitId);

  const WorldArtifactLocation.stored({required String cityId})
    : this._(kind: WorldArtifactLocationKind.stored, cityId: cityId);

  const WorldArtifactLocation.excavation({
    required String unitId,
    required int col,
    required int row,
    required int remainingTurns,
  }) : this._(
         kind: WorldArtifactLocationKind.excavation,
         unitId: unitId,
         col: col,
         row: row,
         remainingTurns: remainingTurns,
       );

  factory WorldArtifactLocation.fromJson(Map<String, dynamic> json) {
    final reader = WireJson(json, 'WorldArtifactLocation');
    final kind = reader.requiredEnum('kind', WorldArtifactLocationKind.values);
    return switch (kind) {
      WorldArtifactLocationKind.map => WorldArtifactLocation.map(
        col: reader.requiredInt('col'),
        row: reader.requiredInt('row'),
      ),
      WorldArtifactLocationKind.carried => WorldArtifactLocation.carried(
        unitId: reader.requiredString('unitId'),
      ),
      WorldArtifactLocationKind.stored => WorldArtifactLocation.stored(
        cityId: reader.requiredString('cityId'),
      ),
      WorldArtifactLocationKind.excavation => WorldArtifactLocation.excavation(
        unitId: reader.requiredString('unitId'),
        col: reader.requiredInt('col'),
        row: reader.requiredInt('row'),
        remainingTurns: reader.requiredNonNegativeInt('remainingTurns'),
      ),
    };
  }

  bool get isOnMap => kind == WorldArtifactLocationKind.map;
  bool get isCarried => kind == WorldArtifactLocationKind.carried;
  bool get isStored => kind == WorldArtifactLocationKind.stored;
  bool get isBeingExcavated => kind == WorldArtifactLocationKind.excavation;

  bool occupiesMapTile(int col, int row) =>
      (isOnMap || isBeingExcavated) && this.col == col && this.row == row;

  Map<String, dynamic> toJson() => {
    'kind': kind.name,
    if (col != null) 'col': col,
    if (row != null) 'row': row,
    if (unitId != null) 'unitId': unitId,
    if (cityId != null) 'cityId': cityId,
    if (remainingTurns > 0) 'remainingTurns': remainingTurns,
  };

  @override
  bool operator ==(Object other) =>
      other is WorldArtifactLocation &&
      other.kind == kind &&
      other.col == col &&
      other.row == row &&
      other.unitId == unitId &&
      other.cityId == cityId &&
      other.remainingTurns == remainingTurns;

  @override
  int get hashCode =>
      Object.hash(kind, col, row, unitId, cityId, remainingTurns);
}

class WorldArtifact {
  final String id;
  final WorldArtifactType type;
  final WorldArtifactLocation location;

  const WorldArtifact({
    required this.id,
    required this.type,
    required this.location,
  });

  factory WorldArtifact.placed({
    required WorldArtifactType type,
    required int col,
    required int row,
  }) {
    return WorldArtifact(
      id: idForType(type),
      type: type,
      location: WorldArtifactLocation.map(col: col, row: row),
    );
  }

  factory WorldArtifact.fromJson(Map<String, dynamic> json) {
    final reader = WireJson(json, 'WorldArtifact');
    return WorldArtifact(
      id: reader.requiredString('id'),
      type: WorldArtifactType.fromName(reader.requiredString('type')),
      location: WorldArtifactLocation.fromJson(reader.requiredMap('location')),
    );
  }

  WorldArtifact copyWith({WorldArtifactLocation? location}) {
    return WorldArtifact(
      id: id,
      type: type,
      location: location ?? this.location,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'location': location.toJson(),
  };

  static String idForType(WorldArtifactType type) => 'artifact.${type.name}';

  @override
  bool operator ==(Object other) =>
      other is WorldArtifact &&
      other.id == id &&
      other.type == type &&
      other.location == location;

  @override
  int get hashCode => Object.hash(id, type, location);
}
