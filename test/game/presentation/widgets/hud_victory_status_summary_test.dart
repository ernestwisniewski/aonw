import 'package:aonw/game/domain/game_save.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/presentation/widgets/hud/hud_victory_status_summary.dart';
import 'package:aonw/l10n/generated/app_localizations_en.dart';
import 'package:aonw/map/domain/map_data.dart';
import 'package:aonw/map/domain/map_selection.dart';
import 'package:aonw/map/domain/terrain_type.dart';
import 'package:aonw_core/game/domain/artifact.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/match_rules.dart';
import 'package:aonw_core/game/domain/player.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HudVictoryStatusSummary', () {
    final l10n = AppLocalizationsEn();

    test('describes unlimited games as conquest without turn cap', () {
      final summary = HudVictoryStatusSummary.from(
        gameSave: _save(),
        gameState: null,
        l10n: l10n,
      );

      expect(summary.primaryLabel, 'CONQUEST');
      expect(summary.secondaryLabel, 'NO LIMIT');
      expect(summary.critical, isFalse);
    });

    test('shows remaining turns for score capped games', () {
      final turnLimit = GameLengthConfig.standard60.turnLimit!;
      final summary = HudVictoryStatusSummary.from(
        gameSave: _save(
          turn: turnLimit - 5,
          matchRules: MatchRules.forGameLength(GameLengthConfig.standard60),
        ),
        gameState: _state(),
        l10n: l10n,
      );

      expect(summary.primaryLabel, 'SCORE 5T');
      expect(summary.secondaryLabel, 'ALICE 94');
      expect(summary.critical, isTrue);
    });

    test('shows score cap once the limit is reached', () {
      final turnLimit = GameLengthConfig.standard60.turnLimit!;
      final summary = HudVictoryStatusSummary.from(
        gameSave: _save(
          turn: turnLimit,
          matchRules: MatchRules.forGameLength(GameLengthConfig.standard60),
        ),
        gameState: _state(),
        l10n: l10n,
      );

      expect(summary.primaryLabel, 'SCORE CAP');
      expect(summary.secondaryLabel, 'ALICE 94');
      expect(summary.critical, isTrue);
    });

    test('shows draw when score leaders are tied', () {
      final turnLimit = GameLengthConfig.standard60.turnLimit!;
      final summary = HudVictoryStatusSummary.from(
        gameSave: _save(
          turn: turnLimit - 1,
          matchRules: MatchRules.forGameLength(GameLengthConfig.standard60),
        ),
        gameState: GameState(
          units: [
            GameUnit.produced(
              id: 'warrior_1',
              ownerPlayerId: 'player_1',
              type: GameUnitType.warrior,
              col: 0,
              row: 0,
            ),
            GameUnit.produced(
              id: 'warrior_2',
              ownerPlayerId: 'player_2',
              type: GameUnitType.warrior,
              col: 1,
              row: 1,
            ),
          ],
        ),
        l10n: l10n,
      );

      expect(summary.primaryLabel, 'SCORE 1T');
      expect(summary.secondaryLabel, 'DRAW 15');
    });

    test('shows domination pressure before score cap becomes urgent', () {
      final summary = HudVictoryStatusSummary.from(
        gameSave: _save(
          turn: 10,
          matchRules: MatchRules.forGameLength(GameLengthConfig.standard60),
        ),
        gameState: const GameState(
          cities: [
            GameCity(
              id: 'city_1',
              ownerPlayerId: 'player_1',
              name: 'Roma',
              center: CityHex(col: 0, row: 0),
              controlledHexes: [CityHex(col: 1, row: 0)],
            ),
          ],
        ),
        l10n: l10n,
        mapData: _mapData(4),
        activePlayerId: 'player_1',
      );

      expect(summary.primaryLabel, 'DOM 50%');
      expect(summary.secondaryLabel, 'ALICE 0/10T');
      expect(summary.critical, isFalse);
      expect(
        summary.details,
        contains(
          isA<HudVictoryStatusDetail>()
              .having((detail) => detail.label, 'label', 'Control')
              .having((detail) => detail.value, 'value', '50% / 45%')
              .having((detail) => detail.highlighted, 'highlighted', isTrue),
        ),
      );
      expect(
        summary.details,
        contains(
          isA<HudVictoryStatusDetail>()
              .having((detail) => detail.label, 'label', 'Pressure')
              .having((detail) => detail.value, 'value', 'Hold for 10 turns'),
        ),
      );
      expect(
        summary.tooltip,
        contains('Your goal: hold the threshold for 10 turns more'),
      );
    });

    test('shows domination over slower cultural progress', () {
      final summary = HudVictoryStatusSummary.from(
        gameSave: _save(
          turn: 10,
          matchRules: MatchRules.forGameLength(GameLengthConfig.standard60),
        ),
        gameState: _stateWithCulturalAndDominationRace(
          culturalHoldTurns: 1,
          dominationHoldTurns: 8,
        ),
        l10n: l10n,
        mapData: _mapData(100),
        activePlayerId: 'player_1',
      );

      expect(summary.primaryLabel, 'DOM 50%');
      expect(summary.secondaryLabel, 'BOB 8/10T');
    });

    test('shows cultural progress when it can finish before domination', () {
      final summary = HudVictoryStatusSummary.from(
        gameSave: _save(
          turn: 10,
          matchRules: MatchRules.forGameLength(GameLengthConfig.standard60),
        ),
        gameState: _stateWithCulturalAndDominationRace(
          culturalHoldTurns: 4,
          dominationHoldTurns: 8,
        ),
        l10n: l10n,
        mapData: _mapData(100),
        activePlayerId: 'player_1',
      );

      expect(summary.primaryLabel, 'HERITAGE');
      expect(summary.secondaryLabel, '4/5 TURNS');
    });

    test('warns when a standard opponent is close to domination', () {
      final baseRules = MatchRules.forGameLength(GameLengthConfig.standard60);
      final warningRules = baseRules.copyWith(
        victory: baseRules.victory.copyWith(dominationHoldTurns: 4),
      );
      final summary = HudVictoryStatusSummary.from(
        gameSave: _save(turn: 10, matchRules: warningRules),
        gameState: _stateWithOpponentControl(
          55,
          holdTurnsByPlayerId: const {'player_2': 3},
        ),
        l10n: l10n,
        mapData: _mapData(100),
        activePlayerId: 'player_1',
      );

      expect(summary.primaryLabel, 'DOM 55%');
      expect(summary.secondaryLabel, 'BOB 3/4T');
      expect(summary.critical, isTrue);
      expect(summary.tooltip, contains('Rival is close to domination'));
      expect(
        summary.details,
        contains(
          isA<HudVictoryStatusDetail>()
              .having((detail) => detail.label, 'label', 'Pressure')
              .having((detail) => detail.value, 'value', 'Break Bob: 1 turn')
              .having((detail) => detail.highlighted, 'highlighted', isTrue),
        ),
      );
    });

    test('does not warn before threshold in unlimited games', () {
      final summary = HudVictoryStatusSummary.from(
        gameSave: _save(matchRules: MatchRules.standard),
        gameState: _stateWithOpponentControl(59),
        l10n: l10n,
        mapData: _mapData(100),
        activePlayerId: 'player_1',
      );

      expect(summary.primaryLabel, 'DOM 59%');
      expect(summary.secondaryLabel, 'BOB / 60%');
      expect(summary.critical, isFalse);
    });
  });
}

GameState _stateWithCulturalAndDominationRace({
  required int culturalHoldTurns,
  required int dominationHoldTurns,
}) {
  return GameState(
    cities: [
      const GameCity(
        id: 'city_1',
        ownerPlayerId: 'player_1',
        name: 'Roma',
        center: CityHex(col: 99, row: 0),
      ),
      GameCity(
        id: 'city_2',
        ownerPlayerId: 'player_2',
        name: 'Antium',
        center: const CityHex(col: 0, row: 0),
        controlledHexes: [
          for (var col = 1; col < 50; col++) CityHex(col: col, row: 0),
        ],
      ),
    ],
    artifacts: [
      for (final type in WorldArtifactType.values.take(6))
        WorldArtifact(
          id: WorldArtifact.idForType(type),
          type: type,
          location: const WorldArtifactLocation.stored(cityId: 'city_1'),
        ),
    ],
    culturalVictoryHoldTurnsByPlayerId: {'player_1': culturalHoldTurns},
    dominationHoldTurnsByPlayerId: {'player_2': dominationHoldTurns},
  );
}

GameSave _save({int turn = 2, MatchRules matchRules = MatchRules.standard}) {
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
    players: const [
      Player(id: 'player_1', name: 'Alice', colorValue: 0xFF4a7fc4),
      Player(id: 'player_2', name: 'Bob', colorValue: 0xFFc45050),
    ],
  );
}

GameState _state() {
  return GameState(
    units: [
      GameUnit.produced(
        id: 'warrior_1',
        ownerPlayerId: 'player_1',
        type: GameUnitType.warrior,
        col: 0,
        row: 0,
      ),
      GameUnit.produced(
        id: 'warrior_2',
        ownerPlayerId: 'player_2',
        type: GameUnitType.warrior,
        col: 1,
        row: 1,
      ),
    ],
    cities: const [
      GameCity(
        id: 'city_1',
        ownerPlayerId: 'player_1',
        name: 'Roma',
        center: CityHex(col: 0, row: 0),
      ),
    ],
  );
}

GameState _stateWithOpponentControl(
  int controlledTiles, {
  Map<String, int> holdTurnsByPlayerId = const {},
}) {
  return GameState(
    cities: [
      const GameCity(
        id: 'city_1',
        ownerPlayerId: 'player_1',
        name: 'Roma',
        center: CityHex(col: 99, row: 0),
      ),
      GameCity(
        id: 'city_2',
        ownerPlayerId: 'player_2',
        name: 'Antium',
        center: const CityHex(col: 0, row: 0),
        controlledHexes: [
          for (var col = 1; col < controlledTiles; col++)
            CityHex(col: col, row: 0),
        ],
      ),
    ],
    dominationHoldTurnsByPlayerId: holdTurnsByPlayerId,
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
