use aonw_contracts::DiplomaticProposalKindDto;
use aonw_domain::{DiplomaticProposalKind, DiplomaticScoreChangeReason};

use super::{decode_proposal_kind, encode_proposal_kind, encode_score_reason};

#[test]
fn proposal_kind_mapping_is_bijective_and_total() {
    for (domain, dto) in [
        (
            DiplomaticProposalKind::Friendship,
            DiplomaticProposalKindDto::Friendship,
        ),
        (
            DiplomaticProposalKind::Truce,
            DiplomaticProposalKindDto::Truce,
        ),
    ] {
        assert_eq!(encode_proposal_kind(domain), dto);
        assert_eq!(decode_proposal_kind(dto), domain);
    }
}

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
