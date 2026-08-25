use aonw_contract_mapping::encode_improvement;
use aonw_contracts::TransportConditionDto;
use aonw_contracts::client::{
    CityFoundingDraftViewDto, ClientReplayVerificationDto, FieldImprovementViewDto, RoadViewDto,
};
use aonw_domain::TransportCondition;

use crate::{
    CityFoundingDraftView, PlayerFieldImprovementView, PlayerRoadView, ReplayVerification,
};

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

pub(super) fn founding_draft(value: &CityFoundingDraftView) -> CityFoundingDraftViewDto {
    CityFoundingDraftViewDto {
        founder_unit_id: value.founder_unit_id().as_str().to_owned(),
        center: coordinate(value.center()),
        controlled_hexes: value
            .controlled_hexes()
            .iter()
            .copied()
            .map(coordinate)
            .collect(),
    }
}
