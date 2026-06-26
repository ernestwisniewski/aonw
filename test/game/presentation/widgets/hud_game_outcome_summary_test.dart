import 'package:aonw/game/domain/game_save.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/presentation/widgets/hud/outcome/hud_game_outcome_summary.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw/map/domain/map_data.dart';
import 'package:aonw/map/domain/map_selection.dart';
import 'package:aonw/map/domain/terrain_type.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/fog.dart';
import 'package:aonw_core/game/domain/hex.dart';
import 'package:aonw_core/game/domain/match_rules.dart';
import 'package:aonw_core/game/domain/player.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppLocalizations l10n;

  setUpAll(() async {
    l10n = await AppLocalizations.delegate.load(const Locale('en'));
  });

  group('HudGameOutcomeSummary', () {
    test('returns null while outcome is ongoing', () {
      final summary = HudGameOutcomeSummary.from(
        l10n: l10n,
        gameSave: _save(),
        gameState: GameState(
          units: [
            _unit('warrior_1', 'player_1', 0),
            _unit('warrior_2', 'player_2', 1),
          ],
        ),
        mapData: _mapData(4),
        activePlayerId: 'player_1',
      );

      expect(summary, isNull);
    });

    test('describes victory from active player perspective', () {
      final summary = HudGameOutcomeSummary.from(
        l10n: l10n,
        gameSave: _save(),
        gameState: GameState(units: [_unit('warrior_1', 'player_1', 0)]),
        mapData: _mapData(4),
        activePlayerId: 'player_1',
      );

      expect(summary, isNotNull);
      expect(summary!.title, 'VICTORY');
      expect(summary.tone, HudGameOutcomeTone.victory);
      expect(summary.conditionLabel, 'CONQUEST');
      expect(summary.winnerLabel, 'Alice');
    });

    test('describes defeat from active player perspective', () {
      final summary = HudGameOutcomeSummary.from(
        l10n: l10n,
        gameSave: _save(),
        gameState: GameState(units: [_unit('warrior_1', 'player_1', 0)]),
        mapData: _mapData(4),
        activePlayerId: 'player_2',
      );

      expect(summary, isNotNull);
      expect(summary!.title, 'DEFEAT');
      expect(summary.tone, HudGameOutcomeTone.defeat);
      expect(summary.winnerLabel, 'Alice');
    });

    test('ignores conquest from projected multiplayer visibility state', () {
      final summary = HudGameOutcomeSummary.from(
        l10n: l10n,
        gameSave: _save(gameMode: GameMode.multiplayer),
        gameState: GameState(
          units: [_unit('warrior_1', 'player_1', 0)],
          fogOfWar: _fogFor('player_2', const [HexCoordinate(col: 0, row: 0)]),
        ),
        mapData: _mapData(4),
        activePlayerId: 'player_2',
      );

      expect(summary, isNull);
    });

    test(
      'ignores conquest after local fog recompute restores all fog players',
      () {
        final summary = HudGameOutcomeSummary.from(
          l10n: l10n,
          gameSave: _save(gameMode: GameMode.multiplayer),
          gameState: GameState(
            playerColors: const {
              'player_1': 0xFF4a7fc4,
              'player_2': 0xFFc45050,
            },
            playerGold: const {'player_1': 0},
            units: [_unit('warrior_1', 'player_1', 0)],
            fogOfWar: FogOfWarState(
              players: {
                'player_1': PlayerFogOfWar(
                  playerId: 'player_1',
                  visibleHexes: {const HexCoordinate(col: 0, row: 0)},
                ),
                'player_2': PlayerFogOfWar(playerId: 'player_2'),
              },
            ),
          ),
          mapData: _mapData(4),
          activePlayerId: 'player_1',
        );

        expect(summary, isNull);
      },
    );

    test('describes real multiplayer conquest from a full snapshot', () {
      final summary = HudGameOutcomeSummary.from(
        l10n: l10n,
        gameSave: _save(gameMode: GameMode.multiplayer),
        gameState: GameState(
          playerGold: const {'player_1': 0, 'player_2': 0},
          units: [_unit('warrior_1', 'player_1', 0)],
          fogOfWar: FogOfWarState(
            players: {
              'player_1': PlayerFogOfWar(
                playerId: 'player_1',
                visibleHexes: {const HexCoordinate(col: 0, row: 0)},
              ),
              'player_2': PlayerFogOfWar(playerId: 'player_2'),
            },
          ),
        ),
        mapData: _mapData(4),
        activePlayerId: 'player_1',
      );

      expect(summary, isNotNull);
      expect(summary!.tone, HudGameOutcomeTone.victory);
      expect(summary.conditionLabel, 'CONQUEST');
    });

    test('describes score draw with score rows', () {
      final turnLimit = GameLengthConfig.standard60.turnLimit!;
      final summary = HudGameOutcomeSummary.from(
        l10n: l10n,
        gameSave: _save(
          turn: turnLimit,
          matchRules: MatchRules.forGameLength(GameLengthConfig.standard60),
        ),
        gameState: GameState(
          units: [
            _unit('warrior_1', 'player_1', 0),
            _unit('warrior_2', 'player_2', 1),
          ],
        ),
        mapData: _mapData(4),
        activePlayerId: 'player_1',
      );

      expect(summary, isNotNull);
      expect(summary!.title, 'DRAW');
      expect(summary.conditionLabel, 'SCORE DRAW');
      expect(summary.metrics.map((metric) => metric.label), ['Alice', 'Bob']);
      expect(summary.metrics.map((metric) => metric.value), ['15', '15']);
    });

    test('describes domination with control and hold metrics', () {
      final summary = HudGameOutcomeSummary.from(
        l10n: l10n,
        gameSave: _save(
          matchRules: MatchRules.forGameLength(GameLengthConfig.standard60),
        ),
        gameState: GameState(
          cities: [
            const GameCity(
              id: 'city_1',
              ownerPlayerId: 'player_1',
              name: 'Roma',
              center: CityHex(col: 0, row: 0),
              controlledHexes: [
                CityHex(col: 1, row: 0),
                CityHex(col: 2, row: 0),
              ],
            ),
          ],
          units: [
            GameUnit(
              id: 'warrior_2',
              ownerPlayerId: 'player_2',
              type: GameUnitType.warrior,
              name: 'Warrior',
              col: 3,
              row: 0,
            ),
          ],
          dominationHoldTurnsByPlayerId: {'player_1': 10},
        ),
        mapData: _mapData(4),
        activePlayerId: 'player_1',
      );

      expect(summary, isNotNull);
      expect(summary!.title, 'VICTORY');
      expect(summary.conditionLabel, 'DOMINATION');
      expect(
        summary.metrics.map((metric) => metric.label),
        contains('Map control'),
      );
      expect(
        summary.metrics
            .singleWhere((metric) => metric.label == 'Map control')
            .value,
        '75%',
      );
      expect(
        summary.metrics.singleWhere((metric) => metric.label == 'Hold').value,
        '10/10 turns',
      );
    });
  });
}

GameSave _save({
  int turn = 2,
  MatchRules matchRules = MatchRules.standard,
  GameMode gameMode = GameMode.hotSeat,
}) {
  return GameSave(
    id: 'save',
    name: 'Game',
    mapName: 'verdantia',
    mapSource: MapSource.asset,
    turn: turn,
    playerStates: const {
      'player_1': PlayerTurnState.active,
      'player_2': PlayerTurnState.active,
    },
    savedAt: DateTime.utc(2026, 5, 11),
    camera: CameraState.zero,
    matchRules: matchRules,
    gameMode: gameMode,
    players: const [
      Player(id: 'player_1', name: 'Alice', colorValue: 0xFF4a7fc4),
      Player(id: 'player_2', name: 'Bob', colorValue: 0xFFc45050),
    ],
  );
}

FogOfWarState _fogFor(String playerId, Iterable<HexCoordinate> visibleHexes) {
  return FogOfWarState(
    players: {
      playerId: PlayerFogOfWar(
        playerId: playerId,
        visibleHexes: Set<HexCoordinate>.of(visibleHexes),
      ),
    },
  );
}

GameUnit _unit(String id, String ownerPlayerId, int col) {
  return GameUnit.produced(
    id: id,
    ownerPlayerId: ownerPlayerId,
    type: GameUnitType.warrior,
    col: col,
    row: 0,
  );
}

MapData _mapData(int validTiles) {
  return MapData(
    cols: validTiles,
    rows: 1,
    tiles: [
      for (var col = 0; col < validTiles; col++)
        TileData(
          col: col,
          row: 0,
          terrains: const [TerrainType.grassland],
          resources: const [],
          height: 0,
        ),
    ],
  );
}
