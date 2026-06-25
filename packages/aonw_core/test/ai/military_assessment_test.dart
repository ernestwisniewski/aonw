import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

void main() {
  group('AiMilitaryAssessment', () {
    test(
      'counts combat units and queued military without civilian carriers',
      () {
        final mapData = _map();
        final view = GameView.fromPersistentState(
          PersistentGameState(
            units: [
              GameUnit.produced(
                id: 'warrior_1',
                ownerPlayerId: 'player_1',
                type: GameUnitType.warrior,
                col: 0,
                row: 0,
              ),
              GameUnit.produced(
                id: 'worker_1',
                ownerPlayerId: 'player_1',
                type: GameUnitType.worker,
                col: 1,
                row: 0,
              ),
              GameUnit.produced(
                id: 'settler_1',
                ownerPlayerId: 'player_1',
                type: GameUnitType.settler,
                col: 2,
                row: 0,
              ),
              GameUnit.startingCommander(
                ownerPlayerId: 'player_1',
                col: 3,
                row: 0,
                army: const [ArmyTroop(type: TroopType.settler, count: 1)],
              ),
            ],
            cities: [
              GameCity(
                id: 'capital',
                ownerPlayerId: 'player_1',
                name: 'Capital',
                center: const CityHex(col: 0, row: 0),
                productionQueue: CityProductionQueue.unit(
                  unitType: GameUnitType.archer,
                  investedProduction: 0,
                ),
              ),
            ],
          ),
          forPlayerId: 'player_1',
          turn: 2,
          mapData: mapData,
          ruleset: GameRuleset.defaults,
        );

        const assessment = AiMilitaryAssessment();

        expect(
          assessment.ownMilitaryCount(view, GameRuleset.defaults.combat),
          1,
        );
        expect(
          assessment.ownMilitaryCountWithQueues(
            view,
            GameRuleset.defaults.combat,
          ),
          2,
        );
        expect(
          assessment.ownMilitaryUnits(view, GameRuleset.defaults.combat),
          hasLength(1),
        );
        expect(
          assessment.isMilitaryType(
            GameUnitType.worker,
            GameRuleset.defaults.combat,
          ),
          isFalse,
        );
      },
    );

    test('treats a guaranteed kill as safe for the last military unit', () {
      final attacker = GameUnit.produced(
        id: 'warrior_1',
        ownerPlayerId: 'player_1',
        type: GameUnitType.warrior,
        col: 0,
        row: 0,
      );
      final defender = GameUnit(
        id: 'enemy_1',
        ownerPlayerId: 'player_2',
        type: GameUnitType.warrior,
        name: GameUnitType.warrior.defaultNameToken,
        col: 1,
        row: 0,
        hitPoints: 1,
      );

      expect(
        const AiMilitaryAssessment().lastMilitarySurvivesAttack(
          attacker: attacker,
          defender: defender,
          ruleset: GameRuleset.defaults.combat,
        ),
        isTrue,
      );
    });
  });
}

MapData _map() {
  return MapData(
    cols: 4,
    rows: 1,
    tiles: [
      for (var col = 0; col < 4; col++)
        TileData(
          col: col,
          row: 0,
          terrains: const [TerrainType.plains],
          resources: const [],
          height: 0,
        ),
    ],
  );
}
