import 'package:aonw_core/application.dart';
import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

void main() {
  test('sequential end advances from a middle canonical participant', () {
    final snapshot = CanonicalGameSnapshot.snapshot(
      domain: DomainState.snapshot(
        turn: 7,
        matchRules: MatchRules.standard,
        participants: const [
          Player(id: 'player_2', name: 'Two', colorValue: 2),
          Player(id: 'player_1', name: 'One', colorValue: 1),
          Player(id: 'player_3', name: 'Three', colorValue: 3),
        ],
        units: [_queuedUnit],
      ),
      session: MatchSessionState.snapshot(
        gameMode: GameMode.hotSeat,
        turnStatesByPlayerId: const {
          'player_2': PlayerTurnState.active,
          'player_1': PlayerTurnState.active,
          'player_3': PlayerTurnState.active,
        },
      ),
      metadata: GameSnapshotMetadata(
        id: 'turn',
        schemaVersion: 3,
        name: 'Turn',
        world: const WorldReference(name: 'turn', source: MapSource.asset),
        savedAtUtc: DateTime.utc(2026, 7, 30, 11),
        camera: GameSnapshotCamera.zero,
      ),
    );

    final result = const GameEngine().apply(
      snapshot: snapshot,
      command: const EndTurnCommand('player_1'),
      context: GameEngineContext(
        actorPlayerId: 'player_1',
        mapView: _map,
        ruleset: GameRuleset.defaults,
        commandTick: 7,
        turnPlayerIds: const ['player_2', 'player_1', 'player_3'],
        savedAt: DateTime.utc(2026, 7, 30, 12),
      ),
    );

    expect(result, isA<GameEngineAccepted>());
    final accepted = result as GameEngineAccepted;
    expect(accepted.snapshot.domain.turn, 7);
    expect(accepted.snapshot.domain.units.single.col, 1);
    expect(accepted.movementDelta.executions.single.unitId, 'queued_unit');
  });
}

final _queuedUnit = GameUnit(
  id: 'queued_unit',
  ownerPlayerId: 'player_3',
  type: GameUnitType.warrior,
  name: GameUnitType.warrior.defaultNameToken,
  col: 0,
  row: 0,
  movementPoints: 0,
  queuedPath: QueuedMovePath(
    targetCol: 1,
    targetRow: 0,
    steps: const [
      UnitMovementStep(col: 1, row: 0, enterCost: 1, cumulativeCost: 1),
    ],
  ),
);

final _map = WorldMapReadView(
  WorldMap(
    cols: 2,
    rows: 1,
    tiles: [
      for (var col = 0; col < 2; col++)
        WorldTile(
          coordinate: HexCoord(col: col, row: 0),
          terrains: const [TerrainType.grassland],
          resources: const [],
          height: 0,
        ),
    ],
  ),
);
