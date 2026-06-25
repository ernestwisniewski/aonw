import 'package:aonw/game/domain/game_save.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/reducer/game_state_transition.dart';
import 'package:aonw/game/domain/turn.dart';
import 'package:aonw/map/domain/map_data.dart';
import 'package:aonw/map/domain/map_selection.dart';
import 'package:aonw_core/game/domain/event.dart';
import 'package:aonw_core/game/domain/player.dart';
import 'package:aonw_core/game/domain/ruleset.dart';
import 'package:flutter_test/flutter_test.dart';

MapData _map() => MapData(cols: 1, rows: 1, tiles: const []);

void main() {
  group('TurnPipeline', () {
    test('runs phases in order and accumulates context output', () {
      const pipeline = TurnPipeline(
        phases: [_AppendEventPhase('p1'), _AppendUiEffectPhase()],
      );

      final result = pipeline.run(
        TurnContext(
          state: const GameState(),
          mapData: _map(),
          ruleset: GameRuleset.defaults,
          playerId: 'p1',
        ),
      );

      expect(result.state, const GameState());
      expect(result.events, [isA<TurnEndedEvent>()]);
      expect(result.uiEffects, [isA<JumpCameraEffect>()]);
    });

    test('returns immutable output lists', () {
      final result = const TurnPipeline(phases: [_AppendEventPhase('p1')]).run(
        TurnContext(
          state: const GameState(),
          mapData: _map(),
          ruleset: GameRuleset.defaults,
          playerId: 'p1',
        ),
      );

      expect(
        () => result.events.add(const TurnEndedEvent(playerId: 'p2')),
        throwsUnsupportedError,
      );
    });

    test('playerEndTurn factory includes processing, fog, and turn event', () {
      final result = TurnPipeline.playerEndTurn().run(
        TurnContext(
          state: const GameState(activePlayerId: 'p1'),
          mapData: _map(),
          ruleset: GameRuleset.defaults,
          playerId: 'p1',
        ),
      );

      expect(result.events, contains(isA<TurnEndedEvent>()));
    });

    test('playerEndTurn advances save snapshot when provided', () {
      final result = TurnPipeline.playerEndTurn().run(
        TurnContext(
          state: const GameState(activePlayerId: 'p1'),
          save: _save(),
          savedAt: DateTime.utc(2026, 4, 24, 14),
          mapData: _map(),
          ruleset: GameRuleset.defaults,
          playerId: 'p1',
        ),
      );

      expect(result.save?.playerStates['p1'], PlayerTurnState.finished);
      expect(result.save?.savedAt, DateTime.utc(2026, 4, 24, 14));
    });

    test('simultaneousTurn factory keeps combat phase as a no-op skeleton', () {
      final result = TurnPipeline.simultaneousTurn().run(
        TurnContext(
          state: const GameState(activePlayerId: 'p1'),
          mapData: _map(),
          ruleset: GameRuleset.defaults,
          playerId: 'p1',
        ),
      );

      expect(result.state.activePlayerId, 'p1');
      expect(result.events, contains(isA<TurnEndedEvent>()));
    });
  });
}

GameSave _save() {
  return GameSave(
    id: 'save_1',
    name: 'Game',
    mapName: 'verdantia',
    mapSource: MapSource.asset,
    turn: 1,
    playerStates: const {
      'p1': PlayerTurnState.active,
      'p2': PlayerTurnState.active,
    },
    savedAt: DateTime.utc(2026, 1, 1),
    camera: CameraState.zero,
    players: const [
      Player(id: 'p1', name: 'Alice', colorValue: 0xFF4a7fc4),
      Player(id: 'p2', name: 'Bob', colorValue: 0xFFc45050),
    ],
  );
}

class _AppendEventPhase extends TurnPhase {
  final String playerId;

  const _AppendEventPhase(this.playerId);

  @override
  TurnContext apply(TurnContext context) {
    return context.copyWith(
      events: [
        ...context.events,
        TurnEndedEvent(playerId: playerId),
      ],
    );
  }
}

class _AppendUiEffectPhase extends TurnPhase {
  const _AppendUiEffectPhase();

  @override
  TurnContext apply(TurnContext context) {
    return context.copyWith(
      uiEffects: [...context.uiEffects, const JumpCameraEffect(col: 1, row: 1)],
    );
  }
}
