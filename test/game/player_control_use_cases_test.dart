import 'package:aonw/game/application/ports/game_repository.dart';
import 'package:aonw/game/application/ports/new_game_request.dart';
import 'package:aonw/game/application/ports/save_snapshot.dart';
import 'package:aonw/game/application/services/player_control_coordinator.dart';
import 'package:aonw/game/application/use_cases/confirm_handoff_use_case.dart';
import 'package:aonw/game/application/use_cases/end_turn_use_case.dart';
import 'package:aonw/game/domain/game_save.dart';
import 'package:aonw/game/domain/turn.dart';
import 'package:aonw/map/domain/map_selection.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/player.dart';
import 'package:flutter_test/flutter_test.dart';

class _MemoryGameRepository implements GameRepository {
  SaveSnapshot snapshot;

  _MemoryGameRepository(this.snapshot);

  @override
  String defaultSaveName(String mapDisplayName, DateTime now) => mapDisplayName;

  @override
  Future<String> create(NewGameRequest request) async => snapshot.save.id;

  @override
  Future<void> delete(String saveId) async {}

  @override
  Future<List<GameSaveIndex>> list() async => const [];

  @override
  Future<SaveSnapshot> load(String saveId) async => snapshot;

  @override
  Future<void> save(SaveSnapshot snapshot) async {
    this.snapshot = snapshot;
  }

  @override
  Future<SaveSnapshot> saveCamera(
    String saveId,
    CameraState camera, {
    DateTime? savedAt,
  }) async {
    throw UnimplementedError();
  }
}

const _player1 = Player(id: 'player_1', name: 'Alice', colorValue: 0xFF4a7fc4);
const _player2 = Player(id: 'player_2', name: 'Bob', colorValue: 0xFFc45050);

GameSave _save({
  int turn = 1,
  Map<String, PlayerTurnState>? playerStates,
  List<Player> players = const [_player1, _player2],
}) {
  return GameSave(
    id: 'save_1',
    name: 'Game',
    mapName: 'verdantia',
    mapSource: MapSource.asset,
    turn: turn,
    playerStates:
        playerStates ??
        const {
          'player_1': PlayerTurnState.active,
          'player_2': PlayerTurnState.active,
        },
    savedAt: DateTime.utc(2026, 4, 16),
    camera: CameraState.zero,
    players: players,
  );
}

void main() {
  group('EndTurnUseCase', () {
    test('selects strategy by game mode', () {
      expect(
        EndTurnStrategies.forMode(GameMode.hotSeat),
        isA<HotSeatEndTurnStrategy>(),
      );
      expect(
        EndTurnStrategies.forMode(GameMode.multiplayer),
        isA<MultiplayerEndTurnStrategy>(),
      );
    });

    test('dispatches end turn and prepares hotseat handoff', () async {
      final save = _save();
      final repository = _MemoryGameRepository(SaveSnapshot(save: save));
      final commands = <GameCommand>[];

      final result =
          await EndTurnUseCase(
            repository: repository,
            strategy: const HotSeatEndTurnStrategy(),
          ).execute(
            save: save,
            control: PlayerControlCoordinator.initial(save),
            dispatch: (command) async {
              commands.add(command);
              repository.snapshot = repository.snapshot.copyWith(
                save: const AdvanceTurnPhase().advanceSave(
                  repository.snapshot.save,
                  playerId: (command as EndTurnCommand).playerId,
                ),
              );
              return const [];
            },
          );

      expect(commands.single, isA<EndTurnCommand>());
      expect(
        result?.updatedSave.playerStates['player_1'],
        PlayerTurnState.finished,
      );
      expect(result?.handoff?.playerId, 'player_2');
      expect(result?.jumpToPlayerId, 'player_2');
      expect(result?.shouldResetMovement, isFalse);
    });

    test('does not prepare hotseat handoff when next player is AI', () async {
      final save = _save(
        players: const [
          _player1,
          Player(
            id: 'player_2',
            name: 'AI Random',
            colorValue: 0xFFc45050,
            kind: PlayerKind.ai,
          ),
        ],
      );
      final repository = _MemoryGameRepository(SaveSnapshot(save: save));

      final result =
          await EndTurnUseCase(
            repository: repository,
            strategy: const HotSeatEndTurnStrategy(),
          ).execute(
            save: save,
            control: PlayerControlCoordinator.initial(save),
            dispatch: (command) async {
              repository.snapshot = repository.snapshot.copyWith(
                save: const AdvanceTurnPhase().advanceSave(
                  repository.snapshot.save,
                  playerId: (command as EndTurnCommand).playerId,
                ),
              );
              return const [];
            },
          );

      expect(result?.handoff, isNull);
      expect(result?.jumpToPlayerId, 'player_2');
      expect(result?.nextControl.activePlayerId, 'player_1');
      expect(result?.nextControl.canAct, isFalse);
    });

    test(
      'does not request client movement reset when a new multiplayer turn starts',
      () async {
        final save = _save(
          playerStates: const {
            'player_1': PlayerTurnState.finished,
            'player_2': PlayerTurnState.active,
          },
        );
        final repository = _MemoryGameRepository(SaveSnapshot(save: save));
        final commands = <GameCommand>[];
        final control = PlayerControlCoordinator.selectPlayer(
          current: PlayerControlCoordinator.initial(save),
          save: save,
          playerId: 'player_2',
        );

        final result =
            await EndTurnUseCase(
              repository: repository,
              strategy: const MultiplayerEndTurnStrategy(),
            ).execute(
              save: save,
              control: control,
              dispatch: (command) async {
                commands.add(command);
                repository.snapshot = repository.snapshot.copyWith(
                  save: repository.snapshot.save.withNewTurn(),
                );
                return const [];
              },
            );

        expect(commands.single, isA<SubmitTurnCommand>());
        expect(result?.updatedSave.turn, 2);
        expect(result?.nextControl.activePlayerId, 'player_2');
        expect(result?.nextControl.canAct, isTrue);
        expect(result?.shouldResetMovement, isFalse);
        expect(result?.handoff, isNull);
      },
    );
  });

  group('ConfirmHandoffUseCase', () {
    test(
      'reloads save and dispatches active player plus movement reset',
      () async {
        final save = _save(
          turn: 2,
          playerStates: const {
            'player_1': PlayerTurnState.active,
            'player_2': PlayerTurnState.active,
          },
        );
        final commands = <GameCommand>[];

        final result =
            await ConfirmHandoffUseCase(
              repository: _MemoryGameRepository(SaveSnapshot(save: save)),
            ).execute(
              saveId: save.id,
              current: const PlayerControlState(activePlayerId: 'player_2'),
              playerId: 'player_1',
              resetMovement: true,
              dispatch: (command) async {
                commands.add(command);
                return const [];
              },
            );

        expect(result?.nextControl.activePlayerId, 'player_1');
        expect(result?.nextControl.canAct, isTrue);
        expect(commands, [
          isA<SetActivePlayerCommand>().having(
            (command) => command.playerId,
            'playerId',
            'player_1',
          ),
          isA<ResetUnitMovementCommand>().having(
            (command) => command.playerId,
            'playerId',
            'player_1',
          ),
        ]);
      },
    );
  });
}
