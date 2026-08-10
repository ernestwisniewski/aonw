import 'package:aonw_core/ai/ai_context.dart';
import 'package:aonw_core/ai/game_view.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/diplomacy.dart';
import 'package:aonw_core/game/domain/hex.dart';

part 'diplomacy_ai_responses.dart';
part 'diplomacy_ai_initiative.dart';

class DiplomacyAiPolicy {
  static const int cooldownTurns = 8;

  const DiplomacyAiPolicy();

  List<DomainCommand> commandsFor(GameView view, AiContext context) {
    final commands = <DomainCommand>[
      ..._proposalResponses(view, context),
      ..._messageResponses(view, context),
    ];
    final initiative = _initiativeCommand(view, context);
    if (initiative != null) commands.add(initiative);
    return commands;
  }

  DomainCommand? _commonEnemyMessage(GameView view, AiContext context) {
    for (final relation in view.diplomacy.relations.values) {
      if (!relation.involves(view.forPlayerId) ||
          relation.status != DiplomaticRelationStatus.war) {
        continue;
      }
      final enemy = relation.playerAId == view.forPlayerId
          ? relation.playerBId
          : relation.playerAId;
      for (final allyRelation in view.diplomacy.relations.values) {
        if (!allyRelation.involves(enemy) ||
            allyRelation.status != DiplomaticRelationStatus.war) {
          continue;
        }
        final target = allyRelation.playerAId == enemy
            ? allyRelation.playerBId
            : allyRelation.playerAId;
        if (target == view.forPlayerId) continue;
        if (_canSendMessage(
          view,
          target,
          DiplomaticMessageTopic.commonEnemy,
          context.turn,
        )) {
          return SendDiplomaticMessageCommand(
            playerId: view.forPlayerId,
            targetPlayerId: target,
            topic: DiplomaticMessageTopic.commonEnemy,
          );
        }
      }
    }
    return null;
  }

  DomainCommand? _warDeclaration(GameView view, AiContext context) {
    final plan = context.strategicPlan;
    if (plan == null || plan.warGoals.isEmpty) return null;
    for (final goal in plan.warGoals) {
      final target = goal.targetPlayerId;
      if (!view.hasDiplomaticContactWith(target)) continue;
      final relation = view.diplomacy.relationBetween(view.forPlayerId, target);
      if (relation.status == DiplomaticRelationStatus.war ||
          relation.status == DiplomaticRelationStatus.friendly ||
          relation.status == DiplomaticRelationStatus.truce ||
          _recentlyTouched(relation, context.turn)) {
        continue;
      }
      if (relation.relationScore > -35 &&
          context.effectiveWeights.aggression < 1.2) {
        continue;
      }
      return DeclareWarCommand(
        playerId: view.forPlayerId,
        targetPlayerId: target,
      );
    }
    return null;
  }
}

extension _DiplomaticRelationAi on DiplomaticRelation {
  bool involves(String playerId) =>
      playerAId == playerId || playerBId == playerId;
}
