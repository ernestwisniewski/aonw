import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/reducer/diplomacy/diplomatic_war_effects.dart';
import 'package:aonw/game/domain/reducer/game_state/game_command_context.dart';
import 'package:aonw/game/domain/reducer/game_state/game_state_transition.dart';
import 'package:aonw/game/domain/reducer/game_state/reducer_player_ids.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/diplomacy.dart';
import 'package:aonw_core/game/domain/event.dart';

abstract final class DiplomaticWarReducer {
  static GameStateTransition declareWar(
    GameState state,
    DeclareWarCommand command, {
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
    if (relation.status == DiplomaticRelationStatus.truce &&
        relation.statusExpiresOnTurn != null &&
        context.combatSeedTurn < relation.statusExpiresOnTurn!) {
      return GameStateTransition(state: state);
    }
    if (relation.status == DiplomaticRelationStatus.war) {
      return GameStateTransition(state: state);
    }

    var diplomacy = state.diplomacy.declareWar(
      playerId: command.playerId,
      targetPlayerId: command.targetPlayerId,
      turn: context.combatSeedTurn,
    );
    final reputation = DiplomaticWarmongerReputation.apply(
      diplomacy: diplomacy,
      aggressorPlayerId: command.playerId,
      victimPlayerId: command.targetPlayerId,
      action: DiplomaticWarmongerAction.declarationOfWar,
      turn: context.combatSeedTurn,
    );
    diplomacy = reputation.diplomacy;

    final nextRelation = diplomacy.relationBetween(
      command.playerId,
      command.targetPlayerId,
    );
    return GameStateTransition(
      state: state.copyWith(
        diplomacy: diplomacy,
        resourceTradeAgreements:
            DiplomaticWarEffects.removeResourceTradeAgreementsBetween(
              state.resourceTradeAgreements,
              command.playerId,
              command.targetPlayerId,
            ),
      ),
      events: [
        DiplomaticRelationChangedEvent(
          playerAId: nextRelation.playerAId,
          playerBId: nextRelation.playerBId,
          oldStatus: relation.status,
          newStatus: nextRelation.status,
          reason: DiplomaticRelationChangeReason.declarationOfWar,
        ),
        _scoreEvent(
          diplomacy,
          command.playerId,
          command.targetPlayerId,
          reason: DiplomaticScoreChangeReason.declarationOfWar,
        ),
        ...DiplomaticWarEffects.warmongerScoreEvents(reputation.entries),
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

  static DiplomaticScoreChangedEvent _scoreEvent(
    DiplomacyState diplomacy,
    String playerAId,
    String playerBId, {
    required DiplomaticScoreChangeReason reason,
    String? sourceId,
  }) {
    final relation = diplomacy.relationBetween(playerAId, playerBId);
    final history = diplomacy.scoreEntriesBetween(playerAId, playerBId);
    final latest = history.isEmpty ? null : history.last;
    return DiplomaticScoreChangedEvent(
      playerAId: relation.playerAId,
      playerBId: relation.playerBId,
      delta: latest?.delta ?? 0,
      scoreAfter: relation.relationScore,
      reason: reason,
      sourceId: sourceId,
    );
  }
}
