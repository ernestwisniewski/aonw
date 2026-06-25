import 'package:aonw_core/ai/mcts/mcts_search_bypass_policy.dart';
import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

void main() {
  group('MctsSearchBypassPolicy', () {
    const policy = MctsSearchBypassPolicy();

    test('bypasses late battery-saver views without tactical contact', () {
      final reason = policy.reasonFor(
        _view(turn: 70),
        canBypassDefaultSearch: true,
        isBatterySaver: true,
      );

      expect(reason, 'no targetable tactical contact');
    });

    test('bypasses late battery-saver single target cleanup', () {
      final reason = policy.reasonFor(
        _view(turn: 70, enemyUnitCount: 1),
        canBypassDefaultSearch: true,
        isBatterySaver: true,
      );

      expect(reason, 'single-unit cleanup');
    });

    test('keeps search for multiple visible targets', () {
      final reason = policy.reasonFor(
        _view(turn: 70, enemyUnitCount: 2),
        canBypassDefaultSearch: true,
        isBatterySaver: true,
      );

      expect(reason, isNull);
    });

    test('keeps search outside default battery-saver runtime', () {
      final lateView = _view(turn: 70);

      expect(
        policy.reasonFor(
          lateView,
          canBypassDefaultSearch: false,
          isBatterySaver: true,
        ),
        isNull,
      );
      expect(
        policy.reasonFor(
          lateView,
          canBypassDefaultSearch: true,
          isBatterySaver: false,
        ),
        isNull,
      );
    });

    test('keeps search when a targetable city is remembered', () {
      final reason = policy.reasonFor(
        _view(turn: 70, rememberedEnemyCity: true),
        canBypassDefaultSearch: true,
        isBatterySaver: true,
      );

      expect(reason, isNull);
    });
  });
}

GameView _view({
  required int turn,
  int enemyUnitCount = 0,
  bool rememberedEnemyCity = false,
}) {
  final mapData = _map();
  return GameView.fromPersistentState(
    PersistentGameState(
      cities: [
        const GameCity(
          id: 'capital',
          ownerPlayerId: 'player_1',
          name: 'Capital',
          center: CityHex(col: 0, row: 0),
        ),
        if (rememberedEnemyCity)
          const GameCity(
            id: 'enemy_city',
            ownerPlayerId: 'player_2',
            name: 'Enemy City',
            center: CityHex(col: 2, row: 2),
          ),
      ],
      units: [
        GameUnit(
          id: 'warrior_1',
          ownerPlayerId: 'player_1',
          type: GameUnitType.warrior,
          name: 'Warrior',
          col: 0,
          row: 0,
        ),
        for (var i = 0; i < enemyUnitCount; i++)
          GameUnit(
            id: 'enemy_$i',
            ownerPlayerId: 'player_2',
            type: GameUnitType.warrior,
            name: 'Enemy',
            col: i + 1,
            row: 0,
          ),
      ],
      fogOfWar: FogOfWarState(
        players: {
          'player_1': PlayerFogOfWar(
            playerId: 'player_1',
            visibleHexes: {
              for (var col = 0; col < 4; col++)
                for (var row = 0; row < 4; row++)
                  HexCoordinate(col: col, row: row),
            },
          ),
        },
      ),
    ),
    forPlayerId: 'player_1',
    turn: turn,
    mapData: mapData,
    ruleset: GameRuleset.defaults,
  );
}

MapData _map() {
  return MapData(
    cols: 4,
    rows: 4,
    tiles: [
      for (var col = 0; col < 4; col++)
        for (var row = 0; row < 4; row++)
          TileData(
            col: col,
            row: row,
            terrains: const [TerrainType.plains],
            resources: const [],
            height: 0,
          ),
    ],
  );
}
