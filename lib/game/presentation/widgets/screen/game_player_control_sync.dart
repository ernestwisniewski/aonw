import 'package:aonw/game/application/services/player_control_coordinator.dart';
import 'package:aonw/game/domain/game_save.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/presentation/providers.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class GamePlayerControlSync extends ConsumerStatefulWidget {
  final GameSave? gameSave;

  const GamePlayerControlSync({required this.gameSave, super.key});

  @override
  ConsumerState<GamePlayerControlSync> createState() =>
      _GamePlayerControlSyncState();
}

class _GamePlayerControlSyncState extends ConsumerState<GamePlayerControlSync> {
  PlayerControlState? _lastSyncedControl;
  PlayerControlState? _pendingSyncControl;
  GameSave? _pendingSyncSave;
  String? _pendingSyncPreferredPlayerId;

  @override
  Widget build(BuildContext context) {
    final scopedSave = ref.watch(gamePlayerControlSaveProvider);
    assert(scopedSave == widget.gameSave);
    final control = ref.watch(gamePlayerControlControllerProvider);
    final gameState = widget.gameSave == null
        ? null
        : ref.watch(gameStateProvider(widget.gameSave!.id)).value;
    if (_gameStateMatchesControl(gameState, control)) {
      _lastSyncedControl = control;
      return const SizedBox.shrink();
    }
    final preferredPlayerId = ref.watch(networkSessionProvider)?.playerId;
    final expected = PlayerControlCoordinator.normalizeForPlayer(
      current: control,
      save: widget.gameSave,
      preferredPlayerId: preferredPlayerId,
    );
    if (control != expected || _lastSyncedControl != expected) {
      _scheduleSync(expected: expected, preferredPlayerId: preferredPlayerId);
    }
    return const SizedBox.shrink();
  }

  bool _gameStateMatchesControl(
    GameState? gameState,
    PlayerControlState control,
  ) {
    return gameState != null &&
        gameState.activePlayerId == control.activePlayerId &&
        gameState.activePlayerCanAct == control.canAct;
  }

  void _scheduleSync({
    required PlayerControlState expected,
    required String? preferredPlayerId,
  }) {
    final save = widget.gameSave;
    if (_pendingSyncControl == expected &&
        _pendingSyncSave == save &&
        _pendingSyncPreferredPlayerId == preferredPlayerId) {
      return;
    }

    _pendingSyncControl = expected;
    _pendingSyncSave = save;
    _pendingSyncPreferredPlayerId = preferredPlayerId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_pendingSyncControl != expected ||
          _pendingSyncSave != save ||
          _pendingSyncPreferredPlayerId != preferredPlayerId) {
        return;
      }
      _pendingSyncControl = null;
      _pendingSyncSave = null;
      _pendingSyncPreferredPlayerId = null;
      if (!mounted || widget.gameSave != save) return;
      ref
          .read(gamePlayerControlControllerProvider.notifier)
          .syncWithSave(save, preferredPlayerId: preferredPlayerId);
      _lastSyncedControl = expected;
    });
  }
}
