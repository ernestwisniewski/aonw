import 'dart:async';

import 'package:aonw/game/application/services/game_session.dart';
import 'package:aonw/game/application/services/player_control_coordinator.dart';
import 'package:aonw/game/domain/reducer/turn/turn_reducer.dart';
import 'package:aonw/game/presentation/input/gamepad/gamepad_input.dart';
import 'package:aonw/game/presentation/providers.dart';
import 'package:aonw/game/presentation/widgets/hud/turn/turn_action_hint.dart';
import 'package:aonw/game/presentation/widgets/screen/game_primary_action_shortcut_scope.dart';
import 'package:aonw_core/game/domain/player.dart';
import 'package:aonw_core/game/domain/save.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class GamePrimaryActionController extends ConsumerStatefulWidget {
  const GamePrimaryActionController({
    required this.session,
    required this.gameSave,
    required this.animatingUnitIdsListenable,
    required this.gamepadInputListenable,
    required this.child,
    super.key,
  });

  final GameSession session;
  final GameSave? gameSave;
  final ValueListenable<Set<String>> animatingUnitIdsListenable;
  final ValueListenable<GamepadInputSnapshot> gamepadInputListenable;
  final Widget child;

  @override
  ConsumerState<GamePrimaryActionController> createState() =>
      _GamePrimaryActionControllerState();
}

class _GamePrimaryActionControllerState
    extends ConsumerState<GamePrimaryActionController> {
  @override
  Widget build(BuildContext context) {
    return GamepadPanelInputListener(
      input: widget.gamepadInputListenable,
      enabled: widget.gameSave != null && widget.session.saveId.isNotEmpty,
      priority: GamepadInputRoutePriority.primary,
      onPrimaryAction: _activate,
      onFocusPrevious: () => _focusPendingAction(actionStep: -1),
      onFocusNext: () => _focusPendingAction(actionStep: 1),
      child: GamePrimaryActionShortcutScope(
        enabled: widget.gameSave != null && widget.session.saveId.isNotEmpty,
        onActivate: _activate,
        child: widget.child,
      ),
    );
  }

  void _activate() {
    final save = widget.gameSave;
    final session = widget.session;
    if (save == null || session.saveId.isEmpty) return;
    if (widget.animatingUnitIdsListenable.value.isNotEmpty) return;

    final playerControl = PlayerControlCoordinator.normalize(
      current: ref.read(gamePlayerControlControllerProvider),
      save: save,
    );
    final activePlayerId = playerControl.activePlayerId;
    if (activePlayerId.isEmpty || !playerControl.canAct) return;
    if (save.playerStates[activePlayerId] == PlayerTurnState.finished) {
      return;
    }

    final gameState = ref.read(gameStateProvider(session.saveId)).value;
    if (gameState == null || gameState.hasSubmittedTurn(activePlayerId)) {
      return;
    }

    final technologyViewModel = ref.read(
      technologyPanelViewModelProvider(session.saveId, activePlayerId),
    );
    final readyToEndTurn = hudPlayerReadyToEndTurn(
      gameState: gameState,
      activePlayerId: activePlayerId,
      technologyViewModel: technologyViewModel,
    );
    final pendingActionCount = TurnReducer.pendingTurnActionCount(
      gameState,
      activePlayerId,
      session.mapData,
      technologyRuleset: ref.read(technologyRulesetProvider),
    );
    final dispatcher = ref.read(hudCommandDispatcherProvider);

    if (pendingActionCount > 0) {
      _focusPendingAction(actionStep: 1);
      return;
    }

    unawaited(
      dispatcher.endTurn(
        animatingUnitIdsListenable: widget.animatingUnitIdsListenable,
        gameSave: save,
        activePlayerId: activePlayerId,
        readyToEndTurn: readyToEndTurn,
        currentState: () => ref.read(gameStateProvider(session.saveId)).value,
      ),
    );
  }

  void _focusPendingAction({required int actionStep}) {
    final save = widget.gameSave;
    final session = widget.session;
    if (save == null || session.saveId.isEmpty) return;
    if (widget.animatingUnitIdsListenable.value.isNotEmpty) return;

    final playerControl = PlayerControlCoordinator.normalize(
      current: ref.read(gamePlayerControlControllerProvider),
      save: save,
    );
    final activePlayerId = playerControl.activePlayerId;
    if (activePlayerId.isEmpty || !playerControl.canAct) return;
    if (save.playerStates[activePlayerId] == PlayerTurnState.finished) {
      return;
    }

    final gameState = ref.read(gameStateProvider(session.saveId)).value;
    if (gameState == null || gameState.hasSubmittedTurn(activePlayerId)) {
      return;
    }

    final pendingActionCount = TurnReducer.pendingTurnActionCount(
      gameState,
      activePlayerId,
      session.mapData,
      technologyRuleset: ref.read(technologyRulesetProvider),
    );
    if (pendingActionCount <= 0) return;

    unawaited(
      ref
          .read(hudCommandDispatcherProvider)
          .focusNextAction(
            activePlayerId: activePlayerId,
            currentState: () =>
                ref.read(gameStateProvider(session.saveId)).value,
            actionStep: actionStep,
          ),
    );
  }
}
