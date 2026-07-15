import 'package:aonw_core/ai/simulation/economy_simulation.dart';
import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

void main() {
  test('reports stored artifact gold and science in turn telemetry', () {
    final baseline = _artifactTelemetryRow();
    final withGold = _artifactTelemetryRow(artifact: _merchantsSeal);
    final withScience = _artifactTelemetryRow(artifact: _astronomersTablets);

    expect(withGold.cityGoldIncome, baseline.cityGoldIncome + 2);
    expect(withGold.netGoldPerTurn, baseline.netGoldPerTurn + 2);
    expect(withScience.sciencePerTurn, baseline.sciencePerTurn + 1);
  });
}

EconomySimulationTurnRow _artifactTelemetryRow({WorldArtifact? artifact}) {
  return EconomySimulationTurnRowProjector.project(
    turn: 1,
    state: PersistentGameState(
      playerColors: const {'player_1': 0xFFDC2626},
      playerGold: const {'player_1': 0},
      cities: const [_city],
      artifacts: artifact == null ? const [] : [artifact],
    ),
    playerId: 'player_1',
    mapData: _mapData,
    ruleset: GameRuleset.defaults,
  );
}

const _city = GameCity(
  id: 'artifact_city',
  ownerPlayerId: 'player_1',
  name: 'Artifact City',
  center: CityHex(col: 0, row: 0),
  controlledHexes: [CityHex(col: 0, row: 0)],
  workedHexes: [CityHex(col: 0, row: 0)],
);

const _merchantsSeal = WorldArtifact(
  id: 'artifact.merchantsSeal',
  type: WorldArtifactType.merchantsSeal,
  location: WorldArtifactLocation.stored(cityId: 'artifact_city'),
);

const _astronomersTablets = WorldArtifact(
  id: 'artifact.astronomersTablets',
  type: WorldArtifactType.astronomersTablets,
  location: WorldArtifactLocation.stored(cityId: 'artifact_city'),
);

final _mapData = MapData(
  cols: 1,
  rows: 1,
  tiles: const [
    TileData(
      col: 0,
      row: 0,
      terrains: [TerrainType.plains],
      resources: [],
      height: 0,
    ),
  ],
);
