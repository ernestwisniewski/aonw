import 'package:aonw_rust_client/aonw_rust_client.dart';

import '../read_model/map_view.dart';
import '../read_model/player_map_view.dart';

final class PlayerMapViewMapper {
  const PlayerMapViewMapper();

  PlayerMapView fromWire(
    AonwPlayerViewSnapshot wire, {
    required MapView map,
    required String actorPlayerId,
  }) {
    if (actorPlayerId.isEmpty) {
      throw const FormatException('Session actor player id is empty.');
    }
    _validateHash(wire.stamp.stateDigest, 'state digest');
    _validateHash(wire.stamp.mapHash, 'map hash');
    _validateHash(wire.stamp.rulesetHash, 'ruleset hash');
    if (wire.stamp.mapHash != map.contentHash) {
      throw const FormatException('Session snapshot belongs to another map.');
    }

    final units = <VisibleUnitView>[];
    String? previousId;
    for (final unit in wire.units) {
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
      final coordinate = (col: unit.coordinate.col, row: unit.coordinate.row);
      if (!map.contains(coordinate)) {
        throw const FormatException(
          'Session snapshot unit is outside the map.',
        );
      }
      units.add(
        VisibleUnitView(
          id: unit.id,
          ownerPlayerId: unit.ownerPlayerId,
          kind: _kind(unit.kind),
          name: unit.name,
          coordinate: coordinate,
          movementUnits: unit.movementUnits,
          posture: _posture(unit.posture),
        ),
      );
      previousId = unit.id;
    }

    return PlayerMapView(
      actorPlayerId: actorPlayerId,
      stamp: SessionStampView(
        behaviorVersion: wire.stamp.behaviorVersion,
        revision: wire.stamp.revision,
        stateDigest: wire.stamp.stateDigest,
        mapHash: wire.stamp.mapHash,
        rulesetHash: wire.stamp.rulesetHash,
      ),
      units: units,
    );
  }

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
