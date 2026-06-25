import 'package:aonw_core/util/collection_equality.dart';

part 'diplomatic_relation.dart';
part 'diplomatic_proposal.dart';
part 'diplomatic_message.dart';
part 'diplomatic_score_entry.dart';
part 'diplomacy_state_model.dart';
part 'diplomacy_json_helpers.dart';

enum DiplomaticRelationStatus { friendly, neutral, hostile, truce, war }

enum DiplomaticRelationChangeReason {
  manual,
  unitAttack,
  cityAttack,
  declarationOfWar,
  proposalAccepted,
  truceExpired,
  messageResponse,
  promiseBroken,
}

enum DiplomaticProposalKind { friendship, truce }

enum DiplomaticMessageCategory {
  warning,
  complaint,
  request,
  praise,
  threat,
  cooperation,
}

enum DiplomaticMessageTopic {
  troopsNearCities,
  citiesTooClose,
  blockedRoutes,
  withdrawScouts,
  avoidEscalation,
  commonEnemy,
  expansionProvocation,
  peacefulPraise,
}

enum DiplomaticMessageResponse { conciliatory, neutral, evasive, aggressive }

enum DiplomaticScoreChangeReason {
  manual,
  unitAttack,
  cityAttack,
  declarationOfWar,
  proposalAccepted,
  proposalRejected,
  messageResponse,
  promiseBroken,
}

extension DiplomaticMessageTopicRules on DiplomaticMessageTopic {
  DiplomaticMessageCategory get category {
    return switch (this) {
      DiplomaticMessageTopic.troopsNearCities =>
        DiplomaticMessageCategory.warning,
      DiplomaticMessageTopic.citiesTooClose =>
        DiplomaticMessageCategory.complaint,
      DiplomaticMessageTopic.blockedRoutes => DiplomaticMessageCategory.request,
      DiplomaticMessageTopic.withdrawScouts =>
        DiplomaticMessageCategory.request,
      DiplomaticMessageTopic.avoidEscalation =>
        DiplomaticMessageCategory.cooperation,
      DiplomaticMessageTopic.commonEnemy =>
        DiplomaticMessageCategory.cooperation,
      DiplomaticMessageTopic.expansionProvocation =>
        DiplomaticMessageCategory.threat,
      DiplomaticMessageTopic.peacefulPraise => DiplomaticMessageCategory.praise,
    };
  }

  bool get canCreateWithdrawalPromise {
    return switch (this) {
      DiplomaticMessageTopic.troopsNearCities ||
      DiplomaticMessageTopic.blockedRoutes ||
      DiplomaticMessageTopic.withdrawScouts => true,
      _ => false,
    };
  }
}

extension DiplomaticMessageResponseRules on DiplomaticMessageResponse {
  int get relationScoreDelta {
    return switch (this) {
      DiplomaticMessageResponse.conciliatory => 12,
      DiplomaticMessageResponse.neutral => 2,
      DiplomaticMessageResponse.evasive => -8,
      DiplomaticMessageResponse.aggressive => -18,
    };
  }

  bool get isPromiseTone => this == DiplomaticMessageResponse.conciliatory;
}
