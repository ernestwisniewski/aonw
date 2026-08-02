import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw_core/domain.dart';

final class PresentationParityStateFixture {
  PresentationParityStateFixture._({
    required this.before,
    required this.after,
    required this.map,
  });

  final GameClientState before;
  final GameClientState after;
  final WorldMap map;

  static PresentationParityStateFixture build() {
    final attacker = GameUnit.produced(
      id: 'attacker_1',
      ownerPlayerId: 'player_1',
      type: GameUnitType.warrior,
      col: 0,
      row: 0,
    );
    final defender = GameUnit.produced(
      id: 'defender_1',
      ownerPlayerId: 'player_2',
      type: GameUnitType.warrior,
      col: 2,
      row: 0,
    );
    final killed = GameUnit.produced(
      id: 'killed_1',
      ownerPlayerId: 'player_2',
      type: GameUnitType.archer,
      col: 3,
      row: 0,
    );
    final worker = GameUnit(
      id: 'worker_1',
      ownerPlayerId: 'player_1',
      type: GameUnitType.worker,
      name: 'Worker',
      col: 1,
      row: 1,
      workerJob: const WorkerJob(
        targetHex: CityHex(col: 4, row: 4),
        improvementType: FieldImprovementType.farm,
        remainingTurns: 1,
        totalTurns: 2,
      ),
    );
    const cities = [
      GameCity(
        id: 'city_1',
        ownerPlayerId: 'player_1',
        name: 'Capital',
        center: CityHex(col: 3, row: 1),
      ),
      GameCity(
        id: 'city_2',
        ownerPlayerId: 'player_2',
        name: 'Rival',
        center: CityHex(col: 4, row: 1),
      ),
    ];
    const colors = {'player_1': 0xFF2563EB, 'player_2': 0xFFDC2626};

    return PresentationParityStateFixture._(
      before: GameClientState(
        activePlayerId: 'player_1',
        activePlayerCanAct: true,
        playerColors: colors,
        cities: cities,
        units: [attacker, defender, killed, worker],
      ),
      after: GameClientState(
        activePlayerId: 'player_1',
        activePlayerCanAct: true,
        playerColors: colors,
        cities: cities,
        units: [
          attacker.copyWith(col: 1, hitPoints: 8),
          defender.copyWith(col: 3, hitPoints: 2),
          worker,
        ],
      ),
      map: _landMap(),
    );
  }
}

WorldMap _landMap() {
  return WorldMap(
    cols: 5,
    rows: 5,
    mapName: 'presentation_parity',
    tiles: [
      for (var row = 0; row < 5; row += 1)
        for (var col = 0; col < 5; col += 1)
          WorldTile.at(
            coordinate: HexCoord(col: col, row: row),
            terrains: const [TerrainType.plains],
            resources: const [],
            height: 0,
          ),
    ],
  );
}
