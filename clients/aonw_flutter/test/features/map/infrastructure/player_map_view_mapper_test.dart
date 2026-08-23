import 'package:aonw_flutter/features/map/infrastructure/player_map_view_mapper.dart';
import 'package:aonw_flutter/features/map/read_model/player_map_view.dart';
import 'package:aonw_rust_client/aonw_rust_client.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/map_test_fixture.dart';

void main() {
  const mapper = PlayerMapViewMapper();

  test('maps the complete recipient-safe unit snapshot', () {
    final map = testMapScene().map;
    final player = mapper.fromWire(
      _snapshot([
        _unit('unit-a', col: 1, row: 0),
        _unit('unit-b', col: 2, row: 1),
      ]),
      map: map,
      actorPlayerId: 'player-1',
    );

    expect(player.stamp.mapHash, map.contentHash);
    expect(player.stamp.revision, 7);
    expect(player.units.map((unit) => unit.id), ['unit-a', 'unit-b']);
    expect(player.units.first.kind, VisibleUnitKind.commander);
    expect(player.units.first.posture, VisibleUnitPosture.active);
    expect(player.units.first.movementUnits, 12);
  });

  test('rejects a snapshot for another map', () {
    final map = testMapScene();

    expect(
      () => mapper.fromWire(
        _snapshot([], mapHash: 'd' * 64),
        map: map.map,
        actorPlayerId: 'player-1',
      ),
      throwsFormatException,
    );
  });

  test('rejects unordered, duplicated, or out-of-map units', () {
    final map = testMapScene().map;

    expect(
      () => mapper.fromWire(
        _snapshot([_unit('unit-b'), _unit('unit-a')]),
        map: map,
        actorPlayerId: 'player-1',
      ),
      throwsFormatException,
    );
    expect(
      () => mapper.fromWire(
        _snapshot([_unit('unit-a'), _unit('unit-a')]),
        map: map,
        actorPlayerId: 'player-1',
      ),
      throwsFormatException,
    );
    expect(
      () => mapper.fromWire(
        _snapshot([_unit('unit-a', col: 99)]),
        map: map,
        actorPlayerId: 'player-1',
      ),
      throwsFormatException,
    );
  });
}

AonwPlayerViewSnapshot _snapshot(
  List<AonwPlayerUnitView> units, {
  String? mapHash,
}) => AonwPlayerViewSnapshot(
  stamp: AonwSessionStamp(
    behaviorVersion: 1,
    revision: 7,
    stateDigest: 'b' * 64,
    mapHash: mapHash ?? 'a' * 64,
    rulesetHash: 'c' * 64,
  ),
  units: units,
);

AonwPlayerUnitView _unit(String id, {int col = 0, int row = 0}) =>
    AonwPlayerUnitView(
      id: id,
      ownerPlayerId: 'player-1',
      kind: AonwUnitKind.commander,
      name: 'Commander',
      coordinate: AonwCoordinate(col: col, row: row),
      movementUnits: 12,
      posture: AonwUnitPosture.active,
    );
