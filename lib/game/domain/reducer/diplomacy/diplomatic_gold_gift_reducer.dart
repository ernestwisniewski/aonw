import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/reducer/game_state/game_command_context.dart';
import 'package:aonw/game/domain/reducer/game_state/game_state_transition.dart';
import 'package:aonw/game/domain/reducer/game_state/reducer_player_ids.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/diplomacy.dart';
import 'package:aonw_core/game/domain/event.dart';

abstract final class DiplomaticGoldGiftReducer {
  static GameStateTransition sendGoldGift(
    GameState state,
    SendGoldGiftCommand command, {
    GameCommandContext context = const GameCommandContext(),
  }) {
    if (!_canIssue(state, command.playerId, context)) {
      return GameStateTransition(state: state);
    }
    if (!_canTargetDiscoveredPlayer(
      state,
      command.playerId,
      command.targetPlayerId,
    )) {
      return GameStateTransition(state: state);
    }
    final relation = state.diplomacy.relationBetween(
      command.playerId,
      command.targetPlayerId,
    );
    if (relation.status == DiplomaticRelationStatus.war ||
        relation.status == DiplomaticRelationStatus.truce) {
      return GameStateTransition(state: state);
    }

    final availableGold = state.playerGold[command.playerId] ?? 0;
    final amount = command.amount.clamp(0, availableGold).toInt();
    final relationDelta = DiplomaticGoldGiftRules.relationDeltaFor(amount);
    if (relationDelta <= 0 ||
        _giftOnCooldown(state, command, context.combatSeedTurn)) {
      return GameStateTransition(state: state);
    }

    final recipientGold = state.playerGold[command.targetPlayerId] ?? 0;
    final sourceId = _sourceId(
      turn: context.combatSeedTurn,
      playerId: command.playerId,
      targetPlayerId: command.targetPlayerId,
    );
    final diplomacy = state.diplomacy.adjustRelationScore(
      command.playerId,
      command.targetPlayerId,
      relationDelta,
      turn: context.combatSeedTurn,
      reason: DiplomaticScoreChangeReason.goldGift,
      sourceId: sourceId,
    );

    return GameStateTransition(
      state: state.copyWith(
        playerGold: {
          ...state.playerGold,
          command.playerId: availableGold - amount,
          command.targetPlayerId: recipientGold + amount,
        },
        diplomacy: diplomacy,
      ),
      events: [
        _scoreEvent(
          diplomacy,
          command.playerId,
          command.targetPlayerId,
          sourceId: sourceId,
        ),
      ],
    );
  }

  static bool _canIssue(
    GameState state,
    String playerId,
    GameCommandContext context,
  ) {
    if (playerId.isEmpty || !context.canAct) return false;
    if (context.hasActor) return context.actorPlayerId == playerId;
    return state.activePlayerId.isEmpty || state.activePlayerId == playerId;
  }

  static bool _canTargetDiscoveredPlayer(
    GameState state,
    String playerId,
    String targetPlayerId,
  ) {
    if (playerId.isEmpty ||
        targetPlayerId.isEmpty ||
        playerId == targetPlayerId) {
      return false;
    }
    if (!knownPlayerIds(state).contains(targetPlayerId)) return false;
    if (state.diplomacy.hasContact(playerId, targetPlayerId)) return true;
    return DiplomaticContact.hasContact(
      playerId: playerId,
      targetPlayerId: targetPlayerId,
      fogOfWar: state.fogOfWar,
      units: state.units,
      cities: state.cities,
    );
  }

  static bool _giftOnCooldown(
    GameState state,
    SendGoldGiftCommand command,
    int turn,
  ) {
    return state.diplomacy
        .scoreEntriesBetween(command.playerId, command.targetPlayerId)
        .any(
          (entry) =>
              entry.reason == DiplomaticScoreChangeReason.goldGift &&
              turn >= entry.turn &&
              turn - entry.turn < DiplomaticGoldGiftRules.cooldownTurns,
        );
  }

  static DiplomaticScoreChangedEvent _scoreEvent(
    DiplomacyState diplomacy,
    String playerAId,
    String playerBId, {
    required String sourceId,
  }) {
    final relation = diplomacy.relationBetween(playerAId, playerBId);
    final history = diplomacy.scoreEntriesBetween(playerAId, playerBId);
    final latest = history.isEmpty ? null : history.last;
    return DiplomaticScoreChangedEvent(
      playerAId: relation.playerAId,
      playerBId: relation.playerBId,
      delta: latest?.delta ?? 0,
      scoreAfter: relation.relationScore,
      reason: DiplomaticScoreChangeReason.goldGift,
      sourceId: sourceId,
    );
  }

  static String _sourceId({
    required int turn,
    required String playerId,
    required String targetPlayerId,
  }) {
    return 'gold_gift.$turn.$playerId.$targetPlayerId';
  }
}
