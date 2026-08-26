use aonw_contracts::client::{ClientSessionStampDto, PlayerViewSnapshotDto};

use crate::{PlayerViewSnapshot, SessionStamp};

use super::{
    artifact, city, field_improvement, founding_draft, pending_action, road, turn_lifecycle, unit,
};

pub(in crate::client_protocol) fn stamp(value: SessionStamp) -> ClientSessionStampDto {
    ClientSessionStampDto {
        revision: value.revision.get(),
        state_digest: value.state_digest.to_string(),
        map_hash: value.map_hash.to_string(),
        ruleset_hash: value.ruleset_hash.to_string(),
    }
}

pub(in crate::client_protocol) fn snapshot(value: &PlayerViewSnapshot) -> PlayerViewSnapshotDto {
    PlayerViewSnapshotDto {
        stamp: stamp(*value.stamp()),
        turn: value.turn(),
        turn_lifecycle: turn_lifecycle(*value.turn_lifecycle()),
        pending_action: value.pending_action().map(pending_action),
        city_founding_draft: value.city_founding_draft().map(founding_draft),
        units: value.units().iter().map(unit).collect(),
        cities: value.cities().iter().map(city).collect(),
        artifacts: value.artifacts().iter().map(artifact).collect(),
        field_improvements: value
            .field_improvements()
            .iter()
            .copied()
            .map(field_improvement)
            .collect(),
        roads: value.roads().iter().copied().map(road).collect(),
    }
}
