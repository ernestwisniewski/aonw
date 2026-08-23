import 'map_view.dart';

enum VisibleUnitKind {
  commander,
  warrior,
  archer,
  settler,
  worker,
  merchant,
  scout,
  spearman,
  cavalry,
  catapult,
  heavyInfantry,
  fieldCannon,
  rifleman,
  tank,
  scoutShip,
  warship,
  reconPlane,
}

enum VisibleUnitPosture { active, fortified, autoExploring, autoWorking }

final class SessionStampView {
  const SessionStampView({
    required this.behaviorVersion,
    required this.revision,
    required this.stateDigest,
    required this.mapHash,
    required this.rulesetHash,
  });

  final int behaviorVersion;
  final int revision;
  final String stateDigest;
  final String mapHash;
  final String rulesetHash;
}

final class VisibleUnitView {
  const VisibleUnitView({
    required this.id,
    required this.ownerPlayerId,
    required this.kind,
    required this.name,
    required this.coordinate,
    required this.movementUnits,
    required this.posture,
  });

  final String id;
  final String ownerPlayerId;
  final VisibleUnitKind kind;
  final String name;
  final MapHexCoordinate coordinate;
  final int movementUnits;
  final VisibleUnitPosture posture;
}

final class PlayerMapView {
  PlayerMapView({required this.stamp, required List<VisibleUnitView> units})
    : units = List.unmodifiable(units);

  final SessionStampView stamp;
  final List<VisibleUnitView> units;

  Iterable<VisibleUnitView> unitsAt(MapHexCoordinate coordinate) =>
      units.where((unit) => unit.coordinate == coordinate);
}
