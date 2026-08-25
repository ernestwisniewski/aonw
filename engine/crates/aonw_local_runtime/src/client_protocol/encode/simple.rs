use aonw_contract_mapping::encode_improvement;
use aonw_contracts::TransportConditionDto;
use aonw_contracts::client::{ClientReplayVerificationDto, FieldImprovementViewDto, RoadViewDto};
use aonw_domain::TransportCondition;

use crate::{PlayerFieldImprovementView, PlayerRoadView, ReplayVerification};

use super::{coordinate, stamp};

pub(crate) fn replay_verification(value: ReplayVerification) -> ClientReplayVerificationDto {
    ClientReplayVerificationDto {
        entry_count: u64::try_from(value.entry_count).unwrap_or(u64::MAX),
        final_event_offset: value.final_event_offset,
        final_stamp: stamp(value.final_stamp),
    }
}

pub(super) fn field_improvement(value: PlayerFieldImprovementView) -> FieldImprovementViewDto {
    FieldImprovementViewDto {
        coordinate: coordinate(value.coordinate()),
        improvement: encode_improvement(value.improvement()),
    }
}

pub(super) fn road(value: PlayerRoadView) -> RoadViewDto {
    RoadViewDto {
        coordinate: coordinate(value.coordinate()),
        condition: match value.condition() {
            TransportCondition::Operational => TransportConditionDto::Operational,
            TransportCondition::Pillaged => TransportConditionDto::Pillaged,
        },
    }
}
