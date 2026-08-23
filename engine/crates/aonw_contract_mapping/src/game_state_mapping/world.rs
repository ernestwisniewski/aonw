use aonw_contracts::{PlayerFogDto, PlayerPairDto, TransportConditionDto, TransportSegmentDto};
use aonw_domain::{CityId, PlayerFog, PlayerId, PlayerPair, TransportCondition, TransportSegment};

use super::error::GameStateMappingError;
use super::value::{decode_coordinate, encode_coordinate};

pub(super) fn decode_fog(
    index: usize,
    dto: PlayerFogDto,
) -> Result<PlayerFog, GameStateMappingError> {
    let player = PlayerId::new(dto.player_id).map_err(|error| {
        GameStateMappingError::new(format!("$.fogOfWar[{index}].playerId"), error.to_string())
    })?;
    Ok(PlayerFog::new(
        player,
        dto.discovered_hexes.into_iter().map(decode_coordinate),
        dto.visible_hexes.into_iter().map(decode_coordinate),
    ))
}

pub(super) fn encode_fog(fog: &PlayerFog) -> PlayerFogDto {
    PlayerFogDto {
        player_id: fog.player_id().as_str().to_owned(),
        discovered_hexes: fog
            .discovered_hexes()
            .iter()
            .copied()
            .map(encode_coordinate)
            .collect(),
        visible_hexes: fog
            .visible_hexes()
            .iter()
            .copied()
            .map(encode_coordinate)
            .collect(),
    }
}

pub(super) fn decode_pair(
    index: usize,
    dto: PlayerPairDto,
) -> Result<PlayerPair, GameStateMappingError> {
    let first = PlayerId::new(dto.first_player_id).map_err(|error| {
        GameStateMappingError::new(
            format!("$.diplomaticContacts[{index}].firstPlayerId"),
            error.to_string(),
        )
    })?;
    let second = PlayerId::new(dto.second_player_id).map_err(|error| {
        GameStateMappingError::new(
            format!("$.diplomaticContacts[{index}].secondPlayerId"),
            error.to_string(),
        )
    })?;
    PlayerPair::new(first, second).ok_or_else(|| {
        GameStateMappingError::new(
            format!("$.diplomaticContacts[{index}]"),
            "self-contact is invalid",
        )
    })
}

pub(super) fn decode_transport(
    index: usize,
    dto: TransportSegmentDto,
) -> Result<TransportSegment, GameStateMappingError> {
    let path = format!("$.transportNetwork[{index}]");
    Ok(TransportSegment::road(
        decode_coordinate(dto.coordinate),
        match dto.condition {
            TransportConditionDto::Operational => TransportCondition::Operational,
            TransportConditionDto::Pillaged => TransportCondition::Pillaged,
        },
        PlayerId::new(dto.built_by_player_id).map_err(|error| {
            GameStateMappingError::new(format!("{path}.builtByPlayerId"), error.to_string())
        })?,
        dto.built_by_city_id
            .map(CityId::new)
            .transpose()
            .map_err(|error| {
                GameStateMappingError::new(format!("{path}.builtByCityId"), error.to_string())
            })?,
    ))
}

pub(super) fn encode_transport(segment: &TransportSegment) -> TransportSegmentDto {
    TransportSegmentDto {
        coordinate: encode_coordinate(segment.coordinate()),
        condition: match segment.condition() {
            TransportCondition::Operational => TransportConditionDto::Operational,
            TransportCondition::Pillaged => TransportConditionDto::Pillaged,
        },
        built_by_player_id: segment.built_by_player_id().as_str().to_owned(),
        built_by_city_id: segment.built_by_city_id().map(|id| id.as_str().to_owned()),
    }
}
