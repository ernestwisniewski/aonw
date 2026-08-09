import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

void main() {
  group('MctsCommandProductionScorer city-site recon', () {
    test('promotes scout production when an active founder lacks recon', () {
      expect(_scoutProductionScore(), 0.30);
    });

    test('does not duplicate an available scout', () {
      expect(_scoutProductionScore(hasAvailableScout: true), 0.11);
    });

    test('does not duplicate a scout already in production', () {
      expect(_scoutProductionScore(hasQueuedScout: true), 0.11);
    });
  });
}

double _scoutProductionScore({
  bool hasAvailableScout = false,
  bool hasQueuedScout = false,
}) {
  final mapData = _mapData();
  final view = GameView.fromDomainState(
    DomainState.snapshot(
      units: [
        GameUnit.produced(
          id: 'settler_1',
          ownerPlayerId: 'player_1',
          type: GameUnitType.settler,
          col: 1,
          row: 0,
        ),
        if (hasAvailableScout)
          GameUnit.produced(
            id: 'scout_1',
            ownerPlayerId: 'player_1',
            type: GameUnitType.scout,
            col: 0,
            row: 1,
          ),
      ],
      cities: [
        GameCity(
          id: 'capital',
          ownerPlayerId: 'player_1',
          name: 'Capital',
          center: const CityHex(col: 0, row: 0),
          productionQueue: hasQueuedScout
              ? CityProductionQueue.unit(
                  unitType: GameUnitType.scout,
                  investedProduction: 0,
                )
              : null,
        ),
      ],
    ),
    forPlayerId: 'player_1',
    turn: 1,
    mapData: mapData,
    ruleset: GameRuleset.defaults,
    ignoreFogOfWar: true,
    ignoreDynamicFogOfWar: true,
  );
  final state = SimulatedState.fromView(view, maxPlanningDepth: 1);
  final context = AiContext(
    ruleset: view.ruleset,
    mapData: mapData,
    turn: view.turn,
    rng: AiRng.fromTurn(
      turn: view.turn,
      playerId: view.forPlayerId,
      baseSeed: 7,
    ),
  );

  return const MctsCommandProductionScorer().score(
    const StartUnitProductionCommand('capital', GameUnitType.scout),
    state: state,
    context: context,
  );
}

WorldMap _mapData() {
  return WorldMap(
    cols: 4,
    rows: 4,
    tiles: [
      for (var col = 0; col < 4; col++)
        for (var row = 0; row < 4; row++)
          WorldTile(
            col: col,
            row: row,
            terrains: const [TerrainType.plains],
            resources: const [],
            height: 0,
          ),
    ],
  );
}
