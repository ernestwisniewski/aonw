import 'package:aonw/game/application/ports/logged_command.dart';
import 'package:aonw/game/application/services/replay_service.dart';
import 'package:aonw/game/domain/game_save.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/presentation/replay/replay_playback_policy.dart';
import 'package:aonw/map/domain/map_selection.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/player.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ReplayPlaybackPolicy', () {
    test('does not fast-forward in all-player perspective', () {
      const policy = ReplayPlaybackPolicy(perspectivePlayerId: null, speed: 1);

      expect(policy.shouldFastForwardActor('p2'), isFalse);
      expect(policy.delayBeforeActor('p2'), const Duration(milliseconds: 1200));
    });

    test('keeps selected player actions at normal speed', () {
      const policy = ReplayPlaybackPolicy(perspectivePlayerId: 'p1', speed: 1);

      expect(policy.shouldFastForwardActor('p1'), isFalse);
      expect(policy.delayBeforeActor('p1'), const Duration(milliseconds: 1200));
    });

    test('fast-forwards actions by other or unknown players', () {
      const policy = ReplayPlaybackPolicy(perspectivePlayerId: 'p1', speed: 1);

      expect(policy.shouldFastForwardActor('p2'), isTrue);
      expect(policy.shouldFastForwardActor(null), isTrue);
      expect(policy.shouldFastForwardActor(''), isTrue);
      expect(policy.delayBeforeActor('p2'), const Duration(milliseconds: 160));
      expect(policy.delayBeforeActor(null), const Duration(milliseconds: 160));
    });

    test('infers actor for legacy unit commands without logged actor', () {
      final unit = GameUnit(
        id: 'warrior_player_1',
        ownerPlayerId: 'player_1',
        type: GameUnitType.warrior,
        name: 'Warrior',
        col: 13,
        row: 4,
      );
      final state = GameState(units: [unit]);
      final step = ReplayStep(
        index: 1,
        loggedCommand: LoggedCommand(
          offset: 85,
          timestamp: DateTime.utc(2026, 6, 7, 12),
          turn: 8,
          command: const StartArtifactExcavationCommand('warrior_player_1'),
        ),
        save: _save,
        previousState: state,
        state: state.copyWith(
          units: [unit.copyWithExcavatingArtifact('artifact_1')],
        ),
        events: const [],
        uiEffects: const [],
      );

      const playerPolicy = ReplayPlaybackPolicy(
        perspectivePlayerId: 'player_1',
        speed: 1,
      );
      const otherPolicy = ReplayPlaybackPolicy(
        perspectivePlayerId: 'player_2',
        speed: 1,
      );

      expect(step.effectiveActorPlayerId, 'player_1');
      expect(playerPolicy.shouldFastForwardStep(step), isFalse);
      expect(
        playerPolicy.delayBeforeStep(step),
        const Duration(milliseconds: 1200),
      );
      expect(otherPolicy.shouldFastForwardStep(step), isTrue);
      expect(
        otherPolicy.delayBeforeStep(step),
        const Duration(milliseconds: 160),
      );
    });

    test('scales normal and fast-forward delays with playback speed', () {
      const policy = ReplayPlaybackPolicy(perspectivePlayerId: 'p1', speed: 2);

      expect(policy.delayBeforeActor('p1'), const Duration(milliseconds: 600));
      expect(policy.delayBeforeActor('p2'), const Duration(milliseconds: 80));
    });

    test('supports 3x playback speed', () {
      const policy = ReplayPlaybackPolicy(perspectivePlayerId: 'p1', speed: 3);

      expect(policy.delayBeforeActor('p1'), const Duration(milliseconds: 400));
      expect(policy.delayBeforeActor('p2'), const Duration(milliseconds: 53));
    });

    test('supports high playback speeds', () {
      const tenX = ReplayPlaybackPolicy(perspectivePlayerId: 'p1', speed: 10);
      const twentyX = ReplayPlaybackPolicy(
        perspectivePlayerId: 'p1',
        speed: 20,
      );

      expect(tenX.delayBeforeActor('p1'), const Duration(milliseconds: 120));
      expect(tenX.delayBeforeActor('p2'), const Duration(milliseconds: 16));
      expect(twentyX.delayBeforeActor('p1'), const Duration(milliseconds: 60));
      expect(twentyX.delayBeforeActor('p2'), const Duration(milliseconds: 8));
    });
  });
}

final _save = GameSave(
  id: 'replay-test',
  name: 'Replay test',
  mapName: 'test',
  mapSource: MapSource.asset,
  turn: 8,
  playerStates: const {
    'player_1': PlayerTurnState.active,
    'player_2': PlayerTurnState.active,
  },
  savedAt: DateTime.utc(2026, 6, 7, 12),
  camera: CameraState.zero,
  players: const [
    Player(id: 'player_1', name: 'Player 1', colorValue: 0xFF3D5FA8),
    Player(id: 'player_2', name: 'Player 2', colorValue: 0xFFB83A3A),
  ],
);
