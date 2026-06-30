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
  static const int minimumTruceGoldPayment =
      ProposalAcceptancePolicy.minimumTruceGoldPayment;

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
    return ProposalAcceptancePolicy.evaluate(
      kind: kind,
      relation: relation,
      recentHostility: recentHostility,
      underPressure: underPressure,
      goldPayment: goldPayment,
    );
  }
}
