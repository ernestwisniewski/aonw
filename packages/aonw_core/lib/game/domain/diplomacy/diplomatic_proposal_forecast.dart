part of 'diplomacy_state.dart';

enum DiplomaticProposalForecastReason {
  acceptableRelations,
  activeWar,
  atWar,
  goldPayment,
  lowRelations,
  militaryPressure,
  recentHostility,
}

final class DiplomaticProposalForecast {
  static const int minimumTruceGoldPayment = 5;

  const DiplomaticProposalForecast({
    required this.accepted,
    required this.reasons,
  });

  final bool accepted;
  final List<DiplomaticProposalForecastReason> reasons;

  static DiplomaticProposalForecast evaluate({
    required DiplomaticProposalKind kind,
    required DiplomaticRelation relation,
    bool recentHostility = false,
    bool underPressure = false,
    int goldPayment = 0,
  }) {
    return switch (kind) {
      DiplomaticProposalKind.friendship => _friendship(
        relation,
        recentHostility: recentHostility,
      ),
      DiplomaticProposalKind.truce => _truce(
        relation,
        underPressure: underPressure,
        goldPayment: goldPayment,
      ),
    };
  }

  static DiplomaticProposalForecast _friendship(
    DiplomaticRelation relation, {
    required bool recentHostility,
  }) {
    final reasons = <DiplomaticProposalForecastReason>[];
    if (relation.status == DiplomaticRelationStatus.war) {
      reasons.add(DiplomaticProposalForecastReason.atWar);
    }
    if (relation.relationScore < -15) {
      reasons.add(DiplomaticProposalForecastReason.lowRelations);
    }
    if (recentHostility) {
      reasons.add(DiplomaticProposalForecastReason.recentHostility);
    }
    if (reasons.isEmpty) {
      reasons.add(DiplomaticProposalForecastReason.acceptableRelations);
    }
    return DiplomaticProposalForecast(
      accepted:
          relation.status != DiplomaticRelationStatus.war &&
          relation.relationScore >= -15 &&
          !recentHostility,
      reasons: List.unmodifiable(reasons),
    );
  }

  static DiplomaticProposalForecast _truce(
    DiplomaticRelation relation, {
    required bool underPressure,
    required int goldPayment,
  }) {
    final reasons = <DiplomaticProposalForecastReason>[];
    if (relation.status == DiplomaticRelationStatus.war) {
      reasons.add(DiplomaticProposalForecastReason.activeWar);
    }
    if (underPressure) {
      reasons.add(DiplomaticProposalForecastReason.militaryPressure);
    }
    if (goldPayment >= minimumTruceGoldPayment) {
      reasons.add(DiplomaticProposalForecastReason.goldPayment);
    }
    if (relation.relationScore >= -35) {
      reasons.add(DiplomaticProposalForecastReason.acceptableRelations);
    }
    final accepted =
        underPressure ||
        goldPayment >= minimumTruceGoldPayment ||
        relation.relationScore >= -35;
    if (!accepted) {
      reasons.add(DiplomaticProposalForecastReason.lowRelations);
    }
    return DiplomaticProposalForecast(
      accepted: accepted,
      reasons: List.unmodifiable(reasons),
    );
  }
}
