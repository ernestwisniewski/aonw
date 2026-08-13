part of 'game_unit.dart';

abstract final class _GameUnitJsonCodec {
  static GameUnit fromJson(Map<String, dynamic> json) {
    return GameUnit(
      id: json['id'] as String,
      ownerPlayerId: json['ownerPlayerId'] as String,
      type: GameUnitType.values.byName(json['type'] as String),
      name: json['name'] as String,
      col: (json['col'] as num).toInt(),
      row: (json['row'] as num).toInt(),
      movementUnits: _movementUnitsFromJson(json),
      army:
          (json['army'] as List<dynamic>?)
              ?.map(
                (value) => ArmyTroop.fromJson(value as Map<String, dynamic>),
              )
              .toList() ??
          const [],
      queuedPath: json['queuedPath'] == null
          ? null
          : QueuedMovePath.fromJson(json['queuedPath'] as Map<String, dynamic>),
      merchantTradeRoute: json['merchantTradeRoute'] == null
          ? null
          : MerchantTradeRoute.fromJson(
              json['merchantTradeRoute'] as Map<String, dynamic>,
            ),
      workerJob: json['workerJob'] == null
          ? null
          : WorkerJob.fromJson(json['workerJob'] as Map<String, dynamic>),
      workerBuildCharges: (json['workerBuildCharges'] as num?)?.toInt(),
      cityFoundingJob: json['cityFoundingJob'] == null
          ? null
          : CityFoundingJob.fromJson(
              json['cityFoundingJob'] as Map<String, dynamic>,
            ),
      workerAssignment: json['workerAssignment'] == null
          ? null
          : WorkerAssignment.fromJson(
              json['workerAssignment'] as Map<String, dynamic>,
            ),
      hitPoints: (json['hitPoints'] as num?)?.toInt(),
      experiencePoints: (json['experiencePoints'] as num?)?.toInt() ?? 0,
      posture: UnitPosture.fromJson(json['posture']),
      carriedArtifactId: _optionalString(json['carriedArtifactId']),
      excavatingArtifactId: _optionalString(json['excavatingArtifactId']),
    );
  }

  static Map<String, dynamic> toJson(GameUnit unit) => {
    'id': unit.id,
    'ownerPlayerId': unit.ownerPlayerId,
    'type': unit.type.name,
    'name': unit.name,
    'col': unit.col,
    'row': unit.row,
    'movementPoints': unit.movementPoints,
    'army': unit.army.map((troop) => troop.toJson()).toList(),
    ..._routeFields(unit),
    ..._workFields(unit),
    ..._statusFields(unit),
  };

  static Map<String, dynamic> _routeFields(GameUnit unit) => {
    if (unit.movementSubpoints > 0) 'movementSubpoints': unit.movementSubpoints,
    if (unit.queuedPath != null) 'queuedPath': unit.queuedPath!.toJson(),
    if (unit.merchantTradeRoute != null)
      'merchantTradeRoute': unit.merchantTradeRoute!.toJson(),
  };

  static Map<String, dynamic> _workFields(GameUnit unit) => {
    if (unit.workerJob != null) 'workerJob': unit.workerJob!.toJson(),
    if (unit.workerBuildCharges !=
        WorkerImprovementChargeRules.startingChargesFor(unit.type))
      'workerBuildCharges': unit.workerBuildCharges,
    if (unit.cityFoundingJob != null)
      'cityFoundingJob': unit.cityFoundingJob!.toJson(),
    if (unit.workerAssignment != null)
      'workerAssignment': unit.workerAssignment!.toJson(),
  };

  static Map<String, dynamic> _statusFields(GameUnit unit) => {
    if (unit.hitPoints != null) 'hitPoints': unit.hitPoints,
    if (unit.experiencePoints > 0) 'experiencePoints': unit.experiencePoints,
    if (unit.posture != UnitPosture.active) 'posture': unit.posture.name,
    if (unit.carriedArtifactId != null)
      'carriedArtifactId': unit.carriedArtifactId,
    if (unit.excavatingArtifactId != null)
      'excavatingArtifactId': unit.excavatingArtifactId,
  };

  static String? _optionalString(Object? value) {
    if (value == null) return null;
    if (value is String && value.isNotEmpty) return value;
    throw ArgumentError.value(
      value,
      'GameUnit.artifactId',
      'Expected a non-empty String or null',
    );
  }

  static int? _movementUnitsFromJson(Map<String, dynamic> json) {
    final movementPoints = (json['movementPoints'] as num?)?.toInt();
    if (movementPoints == null) return null;
    final subpoints = (json['movementSubpoints'] as num?)?.toInt() ?? 0;
    if (subpoints < 0 || subpoints >= MovementPointScale.unitsPerPoint) {
      throw ArgumentError.value(
        subpoints,
        'GameUnit.movementSubpoints',
        'Expected a value from 0 to ${MovementPointScale.unitsPerPoint - 1}',
      );
    }
    return MovementPointScale.unitsFromWholePoints(movementPoints) + subpoints;
  }
}
