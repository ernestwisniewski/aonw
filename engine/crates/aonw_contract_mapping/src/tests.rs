use aonw_domain::DiplomaticScoreChangeReason;

use super::encode_score_reason;

#[test]
fn score_reason_mapping_covers_every_current_domain_value() {
    for value in [
        DiplomaticScoreChangeReason::Manual,
        DiplomaticScoreChangeReason::UnitAttack,
        DiplomaticScoreChangeReason::CityAttack,
        DiplomaticScoreChangeReason::DeclarationOfWar,
        DiplomaticScoreChangeReason::WarmongerPenalty,
        DiplomaticScoreChangeReason::ProposalAccepted,
        DiplomaticScoreChangeReason::ProposalRejected,
        DiplomaticScoreChangeReason::MessageResponse,
        DiplomaticScoreChangeReason::CommonEnemyCooperation,
        DiplomaticScoreChangeReason::GoldGift,
        DiplomaticScoreChangeReason::PromiseBroken,
    ] {
        let _ = encode_score_reason(value);
    }
}
