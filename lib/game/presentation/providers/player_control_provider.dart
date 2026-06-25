import 'dart:async';

import 'package:aonw/game/application/services/game_handoff.dart';
import 'package:aonw/game/application/services/player_control_coordinator.dart';
import 'package:aonw/game/application/use_cases/confirm_handoff_use_case.dart';
import 'package:aonw/game/application/use_cases/end_turn_use_case.dart';
import 'package:aonw/game/domain/game_save.dart';
import 'package:aonw/game/domain/reducer/game_state_transition.dart';
import 'package:aonw/game/presentation/providers/game_actions_provider.dart';
import 'package:aonw/game/presentation/providers/game_state_provider.dart';
import 'package:aonw/game/presentation/providers/handoff_provider.dart';
import 'package:aonw/game/presentation/providers/renderer_provider.dart';
import 'package:aonw/game/presentation/providers/repository_providers.dart';
import 'package:aonw/game/presentation/providers/session_providers.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'player_control_provider.g.dart';

/// Scoped HUD-level provider holding the current [GameSave] for player control.
@Riverpod(dependencies: [])
GameSave? gamePlayerControlSave(Ref ref) => null;

@Riverpod(
  dependencies: [
    gamePlayerControlSave,
    activeGameSession,
    activeRendererViewModel,
    GameCommandController,
    GameStateNotifier,
  ],
)
class GamePlayerControlController extends _$GamePlayerControlController {
  @override
  PlayerControlState build() {
    final save = ref.watch(gamePlayerControlSaveProvider);
    final previous = stateOrNull ?? const PlayerControlState();
    return PlayerControlCoordinator.normalize(current: previous, save: save);
  }

  void syncWithSave(GameSave? save, {String? preferredPlayerId}) {
    _setAndSync(
      PlayerControlCoordinator.normalizeForPlayer(
        current: state,
        save: save,
        preferredPlayerId: preferredPlayerId,
      ),
    );
  }

  void selectPlayer(GameSave? save, String playerId) {
    _setAndSync(
      PlayerControlCoordinator.selectPlayer(
        current: state,
        save: save,
        playerId: playerId,
      ),
    );
  }

  Future<GameSave?> endTurn(GameSave gameSave) async {
    final keepAlive = ref.keepAlive();
    try {
      return await _endTurn(gameSave);
    } finally {
      keepAlive.close();
    }
  }

  Future<GameSave?> _endTurn(GameSave gameSave) async {
    if (state.activePlayerId.isEmpty) return null;

    final session = ref.read(activeGameSessionProvider);
    if (session == null || session.saveId != gameSave.id) return null;

    late final EndTurnResult result;
    final logger = ref.read(gameLoggerProvider);
    HandoffPresentation? pendingPresentation;
    try {
      final endTurnResult =
          await EndTurnUseCase(
            repository: ref.read(gameRepositoryProvider),
            strategy: EndTurnStrategies.forMode(session.gameMode),
          ).execute(
            save: gameSave,
            control: state,
            dispatch: (command) async {
              if (session.gameMode == GameMode.hotSeat &&
                  command is EndTurnCommand) {
                final presentation = await ref
                    .read(gameCommandControllerProvider.notifier)
                    .dispatchForHandoffPresentation(command);
                pendingPresentation = presentation;
                return presentation.uiEffects;
              }
              return _dispatchAndHandle(command);
            },
          );
      if (endTurnResult == null) return null;
      result = endTurnResult;
    } catch (error, stackTrace) {
      logger.warn(
        'GamePlayerControlController',
        'end turn failed',
        error,
        stackTrace,
      );
      return null;
    }

    if (!ref.mounted) return result.updatedSave;

    _invalidateSave(gameSave.id);

    if (result.handoff != null) {
      ref.read(gameHandoffProvider.notifier).setPending(result.handoff!);
      final presentation = pendingPresentation;
      if (presentation != null) {
        ref
            .read(gameCommandControllerProvider.notifier)
            .addHandoffNotifications(presentation);
      }
    } else {
      final presentation = pendingPresentation;
      if (presentation != null) {
        await ref
            .read(gameCommandControllerProvider.notifier)
            .presentHandoffPresentation(presentation);
        if (!ref.mounted) return result.updatedSave;
      }
      _setAndSync(result.nextControl);
      if (result.shouldResetMovement) {
        await _dispatchAndHandle(const ResetUnitMovementCommand());
      }
    }

    return result.updatedSave;
  }

  Future<void> confirmHandoff(
    String playerId, {
    bool resetMovement = true,
  }) async {
    final keepAlive = ref.keepAlive();
    try {
      await _confirmHandoff(playerId, resetMovement: resetMovement);
    } finally {
      keepAlive.close();
    }
  }

  Future<void> _confirmHandoff(
    String playerId, {
    required bool resetMovement,
  }) async {
    final session = ref.read(activeGameSessionProvider);
    if (session == null || session.saveId.isEmpty) return;

    late final ConfirmHandoffResult? result;
    try {
      result =
          await ConfirmHandoffUseCase(
            repository: ref.read(gameRepositoryProvider),
          ).execute(
            saveId: session.saveId,
            current: state,
            playerId: playerId,
            resetMovement: resetMovement,
            dispatch: _dispatchAndHandle,
          );
    } catch (error, stackTrace) {
      if (ref.mounted) {
        ref
            .read(gameLoggerProvider)
            .warn(
              'GamePlayerControlController',
              'confirm handoff failed',
              error,
              stackTrace,
            );
      }
      return;
    }
    if (!ref.mounted || result == null) return;

    if (state != result.nextControl) {
      state = result.nextControl;
    }
  }

  void _invalidateSave(String saveId) {
    if (!ref.mounted) return;
    ref.invalidate(gameSaveSnapshotProvider(saveId));
  }

  void _setAndSync(PlayerControlState next) {
    if (state != next) {
      state = next;
    }
    _syncGameState(next);
  }

  void _syncGameState(PlayerControlState next) {
    final logger = ref.read(gameLoggerProvider);
    unawaited(
      _dispatchAndHandle(
        SetActivePlayerCommand(next.activePlayerId, canAct: next.canAct),
      ).catchError((Object error, StackTrace stackTrace) {
        logger.warn(
          'GamePlayerControlController',
          'game state sync failed',
          error,
          stackTrace,
        );
        return const <UiEffect>[];
      }),
    );
  }

  Future<List<UiEffect>> _dispatchAndHandle(GameCommand command) {
    return ref.read(gameCommandControllerProvider.notifier).dispatch(command);
  }
}
