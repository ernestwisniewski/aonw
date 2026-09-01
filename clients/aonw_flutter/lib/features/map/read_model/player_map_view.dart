import 'map_view.dart';
import 'pending_action_view.dart';

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
    required this.revision,
    required this.stateDigest,
    required this.mapHash,
    required this.rulesetHash,
  });

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
  PlayerMapView({
    required this.actorPlayerId,
    required this.stamp,
    required this.turn,
    required this.pendingAction,
    required List<VisibleUnitView> units,
  }) : units = List.unmodifiable(units);

  final String actorPlayerId;
  final SessionStampView stamp;
  final int turn;
  final PendingActionView? pendingAction;
  final List<VisibleUnitView> units;

  Iterable<VisibleUnitView> unitsAt(MapHexCoordinate coordinate) =>
      units.where((unit) => unit.coordinate == coordinate);

  VisibleUnitView? controlledUnitAt(MapHexCoordinate coordinate) {
    for (final unit in unitsAt(coordinate)) {
      if (unit.ownerPlayerId == actorPlayerId) return unit;
    }
    return null;
  }
}
