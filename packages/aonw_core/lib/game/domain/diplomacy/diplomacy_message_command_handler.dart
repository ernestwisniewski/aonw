import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/diplomacy/diplomacy_command_result.dart';
import 'package:aonw_core/game/domain/diplomacy/diplomacy_command_state.dart';
import 'package:aonw_core/game/domain/diplomacy/diplomacy_command_support.dart';
import 'package:aonw_core/game/domain/diplomacy/diplomacy_state.dart';
import 'package:aonw_core/game/domain/diplomacy/diplomatic_message_effects.dart';
import 'package:aonw_core/game/domain/event.dart';

abstract final class DiplomacyMessageCommandHandler {
  static DiplomacyCommandResult sendMessage({
    required DiplomacyCommandState state,
    required SendDiplomaticMessageCommand command,
    required String actorPlayerId,
    required int turn,
    required bool canAct,
  }) {
    final rejectionReason = _sendRejectionReason(
      state: state,
      command: command,
      actorPlayerId: actorPlayerId,
      turn: turn,
      canAct: canAct,
    );
    if (rejectionReason != null) {
      return DiplomacyCommandSupport.reject(state, rejectionReason);
    }
    final message = DiplomaticMessage.create(
      id:
          command.messageId ??
          'message.$turn.${command.playerId}.${command.targetPlayerId}.'
              '${command.topic.name}.${state.diplomacy.messages.length}',
      fromPlayerId: command.playerId,
      toPlayerId: command.targetPlayerId,
      topic: command.topic,
      createdTurn: turn,
      expiresOnTurn: turn + DiplomacyState.defaultMessageDurationTurns,
    );
    final nextDiplomacy = state.diplomacy.addMessage(message);
    if (identical(nextDiplomacy, state.diplomacy)) {
      return DiplomacyCommandSupport.reject(
        state,
        'diplomacy_message_not_added',
      );
    }
    return DiplomacyCommandSupport.accept(
      state,
      diplomacy: nextDiplomacy,
      events: [
        DiplomaticMessageSentEvent(
          messageId: message.id,
          fromPlayerId: message.fromPlayerId,
          toPlayerId: message.toPlayerId,
          topic: message.topic,
          category: message.category,
          expiresOnTurn: message.expiresOnTurn,
        ),
      ],
    );
  }

  static DiplomacyCommandResult respondMessage({
    required DiplomacyCommandState state,
    required RespondDiplomaticMessageCommand command,
    required String actorPlayerId,
    required int turn,
    required bool canAct,
  }) {
    final issueReason = DiplomacyCommandSupport.issueRejectionReason(
      playerId: command.playerId,
      actorPlayerId: actorPlayerId,
      canAct: canAct,
    );
    if (issueReason != null) {
      return DiplomacyCommandSupport.reject(state, issueReason);
    }
    final message = state.diplomacy.messages[command.messageId];
    if (message == null || message.toPlayerId != command.playerId) {
      return DiplomacyCommandSupport.reject(
        state,
        'diplomacy_message_not_found',
      );
    }
    if (message.responded || message.isExpired(turn)) {
      return DiplomacyCommandSupport.reject(
        state,
        'diplomacy_message_unavailable',
      );
    }
    return _applyResponse(state, message, command.response, turn);
  }

  static DiplomacyCommandResult _applyResponse(
    DiplomacyCommandState state,
    DiplomaticMessage message,
    DiplomaticMessageResponse response,
    int turn,
  ) {
    final cooperationBonus =
        DiplomaticMessageEffects.commonEnemyCooperationBonus(
          state.diplomacy,
          message,
          response,
        );
    final adjustment = state.diplomacy.adjustRelationScoreWithEntry(
      message.fromPlayerId,
      message.toPlayerId,
      DiplomaticMessageEffects.relationDeltaForResponse(
        state.diplomacy,
        message,
        response,
      ),
      turn: turn,
      reason: cooperationBonus == 0
          ? DiplomaticScoreChangeReason.messageResponse
          : DiplomaticScoreChangeReason.commonEnemyCooperation,
      sourceId: message.id,
    );
    final appliedDelta = adjustment.entry?.delta ?? 0;
    final scoreAfter =
        adjustment.entry?.scoreAfter ??
        adjustment.state.relationScoreBetween(
          message.fromPlayerId,
          message.toPlayerId,
        );
    final promiseDueTurn = _promiseDueTurn(message, response, turn);
    final updatedMessage = message.copyWith(
      response: response,
      respondedTurn: turn,
      relationScoreDelta: appliedDelta,
      relationScoreAfter: scoreAfter,
      promiseDueTurn: promiseDueTurn,
    );
    final diplomacy = adjustment.state.updateMessage(updatedMessage);
    return DiplomacyCommandSupport.accept(
      state,
      diplomacy: diplomacy,
      events: [
        _respondedEvent(
          updatedMessage,
          response,
          appliedDelta,
          scoreAfter,
          promiseDueTurn,
        ),
        if (adjustment.entry != null)
          DiplomacyCommandSupport.scoreEvent(adjustment.entry!),
      ],
    );
  }

  static DiplomaticMessageRespondedEvent _respondedEvent(
    DiplomaticMessage message,
    DiplomaticMessageResponse response,
    int relationDelta,
    int relationScoreAfter,
    int? promiseDueTurn,
  ) {
    return DiplomaticMessageRespondedEvent(
      messageId: message.id,
      fromPlayerId: message.fromPlayerId,
      toPlayerId: message.toPlayerId,
      topic: message.topic,
      response: response,
      relationDelta: relationDelta,
      relationScoreAfter: relationScoreAfter,
      promiseDueTurn: promiseDueTurn,
    );
  }

  static int? _promiseDueTurn(
    DiplomaticMessage message,
    DiplomaticMessageResponse response,
    int turn,
  ) => response.isPromiseTone && message.topic.canCreateWithdrawalPromise
      ? turn + DiplomacyState.defaultPromiseDurationTurns
      : null;

  static String? _sendRejectionReason({
    required DiplomacyCommandState state,
    required SendDiplomaticMessageCommand command,
    required String actorPlayerId,
    required int turn,
    required bool canAct,
  }) {
    final issueReason = DiplomacyCommandSupport.issueRejectionReason(
      playerId: command.playerId,
      actorPlayerId: actorPlayerId,
      canAct: canAct,
    );
    if (issueReason != null) return issueReason;
    if (!DiplomacyCommandSupport.canTarget(
      state,
      command.playerId,
      command.targetPlayerId,
    )) {
      return 'diplomacy_target_not_discovered';
    }
    return _messageOnCooldown(state, command, turn)
        ? 'diplomacy_message_cooldown'
        : null;
  }

  static bool _messageOnCooldown(
    DiplomacyCommandState state,
    SendDiplomaticMessageCommand command,
    int turn,
  ) {
    return state.diplomacy
        .messagesBetween(command.playerId, command.targetPlayerId)
        .any(
          (message) =>
              message.fromPlayerId == command.playerId &&
              message.toPlayerId == command.targetPlayerId &&
              message.category == command.topic.category &&
              turn - message.createdTurn < 5,
        );
  }
}
