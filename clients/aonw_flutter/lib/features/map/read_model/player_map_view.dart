import '../../turns/read_model/recipient_turn_view.dart';
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
    required this.turnView,
    required List<VisibleUnitView> units,
  }) : units = List.unmodifiable(units);

  factory PlayerMapView.preview({
    required String actorPlayerId,
    required SessionStampView stamp,
    required int turn,
    required PendingActionView? pendingAction,
    required List<VisibleUnitView> units,
  }) => PlayerMapView(
    actorPlayerId: actorPlayerId,
    stamp: stamp,
    turnView: RecipientTurnView(
      number: turn,
      ownState: RecipientTurnStateView.active,
      ownSubmitted: false,
      requiredSubmissionCount: 1,
      submittedCount: 0,
      pendingAction: pendingAction,
      outcome: GameOutcomeView(
        condition: GameOutcomeConditionView.ongoing,
        winnerPlayerId: null,
        scoreByPlayerId: const {},
      ),
    ),
    units: units,
  );

  final String actorPlayerId;
  final SessionStampView stamp;
  final RecipientTurnView turnView;
  final List<VisibleUnitView> units;

  int get turn => turnView.number;

  PendingActionView? get pendingAction => turnView.pendingAction;

  Iterable<VisibleUnitView> unitsAt(MapHexCoordinate coordinate) =>
      units.where((unit) => unit.coordinate == coordinate);

  VisibleUnitView? controlledUnitAt(MapHexCoordinate coordinate) {
    for (final unit in unitsAt(coordinate)) {
      if (unit.ownerPlayerId == actorPlayerId) return unit;
    }
    return null;
  }
}
