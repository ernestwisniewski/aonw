import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/presentation/widgets/hud/outcome/hud_game_outcome_summary.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw_core/domain/world_map.dart';
import 'package:aonw_core/game/domain/artifact.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/fog.dart';
import 'package:aonw_core/game/domain/hex.dart';
import 'package:aonw_core/game/domain/match_rules.dart';
import 'package:aonw_core/game/domain/outcome.dart';
import 'package:aonw_core/game/domain/player.dart';
import 'package:aonw_core/game/domain/save.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:aonw_core/map/domain/map_selection.dart';
import 'package:aonw_core/map/domain/terrain_type.dart';
import 'package:aonw_core/protocol.dart';
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
        gameState: GameClientState(
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
        gameState: GameClientState(units: [_unit('warrior_1', 'player_1', 0)]),
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
        gameState: GameClientState(units: [_unit('warrior_1', 'player_1', 0)]),
        mapData: _mapData(4),
        activePlayerId: 'player_2',
      );

      expect(summary, isNotNull);
      expect(summary!.title, 'DEFEAT');
      expect(summary.tone, HudGameOutcomeTone.defeat);
      expect(summary.winnerLabel, 'Alice');
    });

    test('detects outcomes for local games encoded as multiplayer', () {
      final summary = HudGameOutcomeSummary.from(
        l10n: l10n,
        gameSave: _save(gameMode: GameMode.multiplayer),
        gameState: GameClientState(units: [_unit('warrior_1', 'player_1', 0)]),
        mapData: _mapData(4),
        activePlayerId: 'player_1',
      );

      expect(summary, isNotNull);
      expect(summary!.title, 'VICTORY');
      expect(summary.conditionLabel, 'CONQUEST');
    });

    test('ignores conquest from projected multiplayer visibility state', () {
      final summary = HudGameOutcomeSummary.from(
        l10n: l10n,
        gameSave: _save(gameMode: GameMode.multiplayer),
        gameState: GameClientState(
          units: [_unit('warrior_1', 'player_1', 0)],
          fogOfWar: _fogFor('player_2', const [HexCoordinate(col: 0, row: 0)]),
        ),
        mapData: _mapData(4),
        activePlayerId: 'player_2',
        networkBackedMultiplayer: true,
      );

      expect(summary, isNull);
    });

    test(
      'ignores conquest after local fog recompute restores all fog players',
      () {
        final summary = HudGameOutcomeSummary.from(
          l10n: l10n,
          gameSave: _save(gameMode: GameMode.multiplayer),
          gameState: GameClientState(
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
          networkBackedMultiplayer: true,
        );

        expect(summary, isNull);
      },
    );

    test('waits for server metadata even with a full multiplayer snapshot', () {
      final summary = HudGameOutcomeSummary.from(
        l10n: l10n,
        gameSave: _save(gameMode: GameMode.multiplayer),
        gameState: GameClientState(
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
        networkBackedMultiplayer: true,
      );

      expect(summary, isNull);
    });

    test('uses terminal server metadata for projected multiplayer state', () {
      final projectedState = GameClientState(
        activePlayerId: 'player_1',
        playerGold: const {'player_2': 0},
        units: [_unit('warrior_1', 'player_1', 0)],
        fogOfWar: _fogFor('player_2', const [HexCoordinate(col: 0, row: 0)]),
      );
      final match = _match(
        outcomeCondition: 'conquest',
        winnerPlayerId: 'player_1',
      );

      final winnerSummary = HudGameOutcomeSummary.from(
        l10n: l10n,
        gameSave: _save(gameMode: GameMode.multiplayer),
        gameState: projectedState,
        mapData: _mapData(4),
        activePlayerId: 'player_1',
        multiplayerMatch: match,
        networkBackedMultiplayer: true,
      );
      final loserSummary = HudGameOutcomeSummary.from(
        l10n: l10n,
        gameSave: _save(gameMode: GameMode.multiplayer),
        gameState: projectedState,
        mapData: _mapData(4),
        activePlayerId: 'player_2',
        multiplayerMatch: match,
        networkBackedMultiplayer: true,
      );

      expect(winnerSummary?.tone, HudGameOutcomeTone.victory);
      expect(winnerSummary?.title, 'VICTORY');
      expect(loserSummary?.tone, HudGameOutcomeTone.defeat);
      expect(loserSummary?.title, 'DEFEAT');
      expect(loserSummary?.conditionLabel, 'CONQUEST');
      expect(loserSummary?.winnerLabel, 'Alice');
    });

    test('describes an authoritative resignation outcome', () {
      final summary = HudGameOutcomeSummary.from(
        l10n: l10n,
        gameSave: _save(gameMode: GameMode.multiplayer),
        gameState: GameClientState(
          playerGold: const {'player_1': 0},
          fogOfWar: _fogFor('player_1', const []),
        ),
        mapData: _mapData(4),
        activePlayerId: 'player_1',
        multiplayerMatch: _match(
          outcomeCondition: 'resignation',
          winnerPlayerId: 'player_1',
        ),
        networkBackedMultiplayer: true,
      );

      expect(summary, isNotNull);
      expect(summary!.outcome.condition, GameOutcomeCondition.resignation);
      expect(summary.tone, HudGameOutcomeTone.victory);
      expect(summary.conditionLabel, 'RESIGNATION');
      expect(summary.subtitle, contains('Alice'));
    });

    test('describes an authoritative multiplayer draw', () {
      final summary = HudGameOutcomeSummary.from(
        l10n: l10n,
        gameSave: _save(gameMode: GameMode.multiplayer),
        gameState: GameClientState(
          playerGold: const {'player_2': 0},
          fogOfWar: _fogFor('player_2', const []),
        ),
        mapData: _mapData(4),
        activePlayerId: 'player_2',
        multiplayerMatch: _match(
          outcomeCondition: 'draw',
          winnerPlayerId: null,
        ),
        networkBackedMultiplayer: true,
      );

      expect(summary, isNotNull);
      expect(summary!.outcome.condition, GameOutcomeCondition.draw);
      expect(summary.tone, HudGameOutcomeTone.draw);
      expect(summary.title, 'DRAW');
      expect(summary.conditionLabel, 'SCORE DRAW');
    });

    test('describes score draw with score rows', () {
      final turnLimit = GameLengthConfig.standard60.turnLimit!;
      final summary = HudGameOutcomeSummary.from(
        l10n: l10n,
        gameSave: _save(
          turn: turnLimit,
          matchRules: MatchRules.forGameLength(GameLengthConfig.standard60),
        ),
        gameState: GameClientState(
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
        gameState: GameClientState(
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

    test('describes cultural progress for a completed local match', () {
      final culturalRules = MatchRules.standard.copyWith(
        victory: const VictoryRules(
          conquestEnabled: false,
          dominationEnabled: false,
          dominationControlPercent: 60,
          dominationHoldTurns: 5,
          scoreFallbackEnabled: false,
          culturalRequiredArtifacts: 1,
          culturalHoldTurns: 1,
        ),
      );
      final summary = HudGameOutcomeSummary.from(
        l10n: l10n,
        gameSave: _save(matchRules: culturalRules),
        gameState: GameClientState(
          cities: const [
            GameCity(
              id: 'city_1',
              ownerPlayerId: 'player_1',
              name: 'Heritage City',
              center: CityHex(col: 0, row: 0),
            ),
            GameCity(
              id: 'city_2',
              ownerPlayerId: 'player_2',
              name: 'Rival City',
              center: CityHex(col: 1, row: 0),
            ),
          ],
          artifacts: const [
            WorldArtifact(
              id: 'artifact_1',
              type: WorldArtifactType.ancientImperialCrown,
              location: WorldArtifactLocation.stored(cityId: 'city_1'),
            ),
          ],
          culturalVictoryHoldTurnsByPlayerId: const {'player_1': 1},
        ),
        mapData: _mapData(4),
        activePlayerId: 'player_1',
      );

      expect(summary, isNotNull);
      expect(summary!.conditionLabel, 'CULTURAL VICTORY');
      expect(summary.metrics.map((metric) => metric.label), [
        'Winner',
        'Condition',
        'Artifacts',
        'Held',
      ]);
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

WorldMap _mapData(int validTiles) {
  return WorldMap(
    cols: validTiles,
    rows: 1,
    tiles: [
      for (var col = 0; col < validTiles; col++)
        WorldTile(
          col: col,
          row: 0,
          terrains: const [TerrainType.grassland],
          resources: const [],
          height: 0,
        ),
    ],
  );
}

WireMatch _match({
  required String outcomeCondition,
  required String? winnerPlayerId,
}) {
  return WireMatch(
    id: 'save',
    ownerUserId: 'user_1',
    name: 'Game',
    mapName: 'verdantia',
    players: const [
      WirePlayer(
        id: 'player_1',
        userId: 'user_1',
        name: 'Alice',
        colorValue: 0xFF4a7fc4,
        kind: WirePlayerKind.human,
        connectionState: WirePlayerConnectionState.connected,
      ),
      WirePlayer(
        id: 'player_2',
        userId: 'user_2',
        name: 'Bob',
        colorValue: 0xFFc45050,
        kind: WirePlayerKind.human,
        connectionState: WirePlayerConnectionState.connected,
      ),
    ],
    turn: 2,
    state: 'finished',
    createdAt: DateTime.utc(2026, 5, 11),
    endedAt: DateTime.utc(2026, 5, 12),
    outcomeCondition: outcomeCondition,
    winnerPlayerId: winnerPlayerId,
  );
}
