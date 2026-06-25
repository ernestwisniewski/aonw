import 'package:aonw/game/domain/game_save.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/presentation/formatters/game_display_names.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw_core/game/domain/player.dart';

class HudCommandLineViewModel {
  final int? activePlayerColorValue;
  final String playerName;
  final String waitingForLabel;
  final String statusLabel;
  final String selectionLabel;
  final int remainingActionCount;
  final String? actionHintLabel;
  final bool activePlayerFinished;
  final bool multiplayer;
  final bool showActionHint;

  const HudCommandLineViewModel({
    required this.activePlayerColorValue,
    required this.playerName,
    required this.waitingForLabel,
    required this.statusLabel,
    required this.selectionLabel,
    required this.remainingActionCount,
    required this.actionHintLabel,
    required this.activePlayerFinished,
    required this.multiplayer,
    required this.showActionHint,
  });

  static HudCommandLineViewModel create({
    required GameSave gameSave,
    required String activePlayerId,
    required bool activePlayerCanAct,
    required GameState? gameState,
    required bool isUnitAnimating,
    required bool readyToEndTurn,
    int remainingActionCount = 0,
    required String? actionHintLabel,
    required AppLocalizations l10n,
  }) {
    final activePlayer = _activePlayer(gameSave, activePlayerId);
    final multiplayer = gameSave.gameMode == GameMode.multiplayer;
    final activePlayerSubmitted =
        activePlayerId.isNotEmpty &&
        (gameState?.hasSubmittedTurn(activePlayerId) ?? false);
    final activePlayerFinished =
        !activePlayerCanAct ||
        gameSave.playerStates[activePlayerId] == PlayerTurnState.finished ||
        activePlayerSubmitted;
    final waitingForLabel = _waitingForLabel(
      gameSave: gameSave,
      gameState: gameState,
      submitted: activePlayerSubmitted,
      multiplayer: multiplayer,
      l10n: l10n,
    );
    final statusLabel = waitingForLabel.isNotEmpty
        ? waitingForLabel
        : activePlayerFinished
        ? l10n.bottomToolbarWaiting
        : multiplayer
        ? l10n.bottomToolbarPlan
        : l10n.bottomToolbarMove;
    final normalizedActionHintLabel =
        actionHintLabel != null && actionHintLabel.trim().isNotEmpty
        ? actionHintLabel.trim()
        : null;

    return HudCommandLineViewModel(
      activePlayerColorValue: activePlayer?.colorValue,
      playerName: activePlayer == null
          ? ''
          : GameDisplayNames.player(l10n, activePlayer),
      waitingForLabel: waitingForLabel,
      statusLabel: statusLabel,
      selectionLabel: _selectionLabel(l10n, gameState),
      remainingActionCount: remainingActionCount,
      actionHintLabel: normalizedActionHintLabel,
      activePlayerFinished: activePlayerFinished,
      multiplayer: multiplayer,
      showActionHint:
          normalizedActionHintLabel != null &&
          !activePlayerFinished &&
          !isUnitAnimating &&
          !readyToEndTurn,
    );
  }

  static Player? _activePlayer(GameSave gameSave, String activePlayerId) {
    for (final player in gameSave.players) {
      if (player.id == activePlayerId) return player;
    }
    return null;
  }

  static String _waitingForLabel({
    required GameSave gameSave,
    required GameState? gameState,
    required bool submitted,
    required bool multiplayer,
    required AppLocalizations l10n,
  }) {
    if (!multiplayer || !submitted) return '';
    final submittedPlayerIds =
        gameState?.submittedPlayerIds ?? const <String>{};
    final waiting = [
      for (final player in gameSave.players)
        if (!submittedPlayerIds.contains(player.id))
          GameDisplayNames.player(l10n, player),
    ];
    if (waiting.isEmpty) return l10n.bottomToolbarResolvingTurn;
    final visible = waiting.take(2).join(', ');
    final suffix = waiting.length > 2 ? ' +${waiting.length - 2}' : '';
    return l10n.bottomToolbarWaitingFor('$visible$suffix');
  }

  static String _selectionLabel(AppLocalizations l10n, GameState? gameState) {
    final selection = gameState?.selection;
    final city = selection?.city;
    if (city != null) {
      return GameDisplayNames.city(l10n, city);
    }
    final unit = gameState?.selectedUnit ?? selection?.unit;
    if (unit != null) {
      return GameDisplayNames.unitType(l10n, unit.type);
    }
    return '';
  }
}
