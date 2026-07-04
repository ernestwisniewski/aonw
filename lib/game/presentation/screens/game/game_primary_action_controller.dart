import 'dart:async';

import 'package:aonw/game/application/services/game_session.dart';
import 'package:aonw/game/application/services/player_control_coordinator.dart';
import 'package:aonw/game/domain/game_save.dart';
import 'package:aonw/game/presentation/input/gamepad/gamepad_input.dart';
import 'package:aonw/game/presentation/providers.dart';
import 'package:aonw/game/presentation/widgets/hud/turn/turn_action_hint.dart';
import 'package:aonw/game/presentation/widgets/screen/game_primary_action_shortcut_scope.dart';
import 'package:aonw_core/game/domain/player.dart';
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
  bool _primaryActionPressed = false;

  @override
  void initState() {
    super.initState();
    widget.gamepadInputListenable.addListener(_handleGamepadInput);
  }

  @override
  void didUpdateWidget(GamePrimaryActionController oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.gamepadInputListenable == widget.gamepadInputListenable) {
      return;
    }
    oldWidget.gamepadInputListenable.removeListener(_handleGamepadInput);
    _primaryActionPressed = widget.gamepadInputListenable.value.primaryAction;
    widget.gamepadInputListenable.addListener(_handleGamepadInput);
  }

  @override
  void dispose() {
    widget.gamepadInputListenable.removeListener(_handleGamepadInput);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GamePrimaryActionShortcutScope(
      enabled: widget.gameSave != null && widget.session.saveId.isNotEmpty,
      onActivate: _activate,
      child: widget.child,
    );
  }

  void _handleGamepadInput() {
    final pressed = widget.gamepadInputListenable.value.primaryAction;
    if (pressed && !_primaryActionPressed) _activate();
    _primaryActionPressed = pressed;
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

    unawaited(
      ref
          .read(hudCommandDispatcherProvider)
          .endTurn(
            animatingUnitIdsListenable: widget.animatingUnitIdsListenable,
            gameSave: save,
            activePlayerId: activePlayerId,
            readyToEndTurn: readyToEndTurn,
            currentState: () =>
                ref.read(gameStateProvider(session.saveId)).value,
          ),
    );
  }
}
