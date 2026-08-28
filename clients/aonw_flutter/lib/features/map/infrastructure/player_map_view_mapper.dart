import 'package:aonw_rust_client/aonw_rust_client.dart';

import '../../turns/read_model/recipient_turn_view.dart';
import '../read_model/map_view.dart';
import '../read_model/player_map_view.dart';
import 'pending_action_view_mapper.dart';

final class PlayerMapViewMapper {
  const PlayerMapViewMapper({
    PendingActionViewMapper pendingActionMapper =
        const PendingActionViewMapper(),
  }) : _pendingActionMapper = pendingActionMapper;

  final PendingActionViewMapper _pendingActionMapper;

  PlayerMapView fromWire(
    AonwPlayerViewSnapshot wire, {
    required MapView map,
    required String actorPlayerId,
  }) {
    _validateSnapshot(wire, map: map, actorPlayerId: actorPlayerId);
    final units = _mapUnits(wire.units, map);
    final pendingAction = _pendingActionMapper.fromWire(
      wire.pendingAction,
      actorPlayerId: actorPlayerId,
      units: units,
      map: map,
    );
    return PlayerMapView(
      actorPlayerId: actorPlayerId,
      stamp: _mapStamp(wire.stamp),
      turnView: RecipientTurnView(
        number: wire.turn,
        ownState: switch (wire.turnLifecycle.ownState) {
          AonwPlayerTurnState.active => RecipientTurnStateView.active,
          AonwPlayerTurnState.finished => RecipientTurnStateView.finished,
          null => null,
        },
        ownSubmitted: wire.turnLifecycle.ownSubmitted,
        requiredSubmissionCount: wire.turnLifecycle.requiredSubmissionCount,
        submittedCount: wire.turnLifecycle.submittedCount,
        pendingAction: pendingAction,
        outcome: GameOutcomeView(
          condition: GameOutcomeConditionView.values.byName(
            wire.outcome.condition.name,
          ),
          winnerPlayerId: wire.outcome.winnerPlayerId,
          scoreByPlayerId: wire.outcome.scoreByPlayerId,
        ),
      ),
      units: units,
    );
  }

  static void _validateSnapshot(
    AonwPlayerViewSnapshot wire, {
    required MapView map,
    required String actorPlayerId,
  }) {
    if (actorPlayerId.isEmpty) {
      throw const FormatException('Session actor player id is empty.');
    }
    _validateStamp(wire.stamp);
    if (wire.stamp.mapHash != map.contentHash) {
      throw const FormatException('Session snapshot belongs to another map.');
    }
    if (wire.turn < 1) {
      throw const FormatException('Session snapshot turn is not positive.');
    }
  }

  static void _validateStamp(AonwSessionStamp stamp) {
    _validateHash(stamp.stateDigest, 'state digest');
    _validateHash(stamp.mapHash, 'map hash');
    _validateHash(stamp.rulesetHash, 'ruleset hash');
  }

  static List<VisibleUnitView> _mapUnits(
    List<AonwPlayerUnitView> source,
    MapView map,
  ) {
    final units = <VisibleUnitView>[];
    String? previousId;
    for (final unit in source) {
      _validateUnit(unit, previousId: previousId, map: map);
      units.add(_mapUnit(unit));
      previousId = unit.id;
    }
    return units;
  }

  static void _validateUnit(
    AonwPlayerUnitView unit, {
    required String? previousId,
    required MapView map,
  }) {
    if (unit.id.isEmpty || unit.ownerPlayerId.isEmpty || unit.name.isEmpty) {
      throw const FormatException(
        'Session snapshot contains an empty unit field.',
      );
    }
    if (previousId != null && previousId.compareTo(unit.id) >= 0) {
      throw const FormatException(
        'Session snapshot unit identifiers are not unique and ordered.',
      );
    }
    if (!map.contains(_coordinate(unit))) {
      throw const FormatException('Session snapshot unit is outside the map.');
    }
  }

  static VisibleUnitView _mapUnit(AonwPlayerUnitView unit) => VisibleUnitView(
    id: unit.id,
    ownerPlayerId: unit.ownerPlayerId,
    kind: _kind(unit.kind),
    name: unit.name,
    coordinate: _coordinate(unit),
    movementUnits: unit.movementUnits,
    posture: _posture(unit.posture),
  );

  static SessionStampView _mapStamp(AonwSessionStamp stamp) => SessionStampView(
    revision: stamp.revision,
    stateDigest: stamp.stateDigest,
    mapHash: stamp.mapHash,
    rulesetHash: stamp.rulesetHash,
  );

  static ({int col, int row}) _coordinate(AonwPlayerUnitView unit) =>
      (col: unit.coordinate.col, row: unit.coordinate.row);

  static void _validateHash(String value, String label) {
    if (!RegExp(r'^[0-9a-f]{64}$').hasMatch(value)) {
      throw FormatException('Session $label is not a canonical digest.');
    }
  }

  static VisibleUnitKind _kind(AonwUnitKind value) =>
      VisibleUnitKind.values.byName(value.name);

  static VisibleUnitPosture _posture(AonwUnitPosture value) =>
      VisibleUnitPosture.values.byName(value.name);
}
