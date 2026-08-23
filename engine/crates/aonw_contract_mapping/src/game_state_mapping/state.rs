use aonw_contracts::{
    GameStateDto, MAX_GAME_STATE_UNIT_COUNT, PlayerPairDto, UnitOccupancyPolicyDto,
};
use aonw_domain::{
    Diplomacy, FogOfWar, GameState, HexGridBounds, StateRevision, TransportNetwork,
    UnitOccupancyPolicy,
};

use super::artifact::{decode_artifact, encode_artifact};
use super::error::GameStateMappingError;
use super::interaction::{decode_interaction, encode_interaction};
use super::unit::{decode_unit, encode_unit};
use super::world::{
    decode_city, decode_fog, decode_pair, decode_transport, encode_city, encode_fog,
    encode_transport,
};

/// Validates and maps a complete game-state DTO.
///
/// # Errors
///
/// Returns a path-aware error for violated invariants.
pub fn decode_game_state(dto: GameStateDto) -> Result<GameState, GameStateMappingError> {
    if dto.units.len() > MAX_GAME_STATE_UNIT_COUNT {
        return Err(GameStateMappingError::new(
            "$.units",
            format!(
                "contains {} units; maximum is {MAX_GAME_STATE_UNIT_COUNT}",
                dto.units.len()
            ),
        ));
    }
    let bounds = HexGridBounds::new(dto.cols, dto.rows)
        .ok_or_else(|| GameStateMappingError::new("$", "map bounds must be non-empty"))?;
    let units = dto
        .units
        .into_iter()
        .enumerate()
        .map(|(index, unit)| decode_unit(index, unit))
        .collect::<Result<Vec<_>, _>>()?;
    let cities = dto
        .cities
        .into_iter()
        .enumerate()
        .map(|(index, city)| decode_city(index, city))
        .collect::<Result<Vec<_>, _>>()?;
    let artifacts = dto
        .artifacts
        .into_iter()
        .enumerate()
        .map(|(index, artifact)| decode_artifact(index, artifact))
        .collect::<Result<Vec<_>, _>>()?;
    let interaction = decode_interaction(dto.interaction)?;
    let fog = FogOfWar::try_new(
        dto.fog_of_war
            .into_iter()
            .enumerate()
            .map(|(index, fog)| decode_fog(index, fog))
            .collect::<Result<Vec<_>, _>>()?,
    )
    .map_err(|player| {
        GameStateMappingError::new("$.fogOfWar", format!("duplicate player: {player}"))
    })?;
    let diplomacy = Diplomacy::new(
        dto.diplomatic_contacts
            .into_iter()
            .enumerate()
            .map(|(index, pair)| decode_pair(index, pair))
            .collect::<Result<Vec<_>, _>>()?,
    );
    let transport = TransportNetwork::try_new(
        dto.transport_network
            .into_iter()
            .enumerate()
            .map(|(index, segment)| decode_transport(index, segment))
            .collect::<Result<Vec<_>, _>>()?,
    )
    .map_err(|coordinate| {
        GameStateMappingError::new(
            "$.transportNetwork",
            format!(
                "duplicate coordinate: ({}, {})",
                coordinate.col(),
                coordinate.row()
            ),
        )
    })?;
    GameState::try_new_with_world(
        StateRevision::new(dto.revision),
        dto.turn,
        bounds,
        match dto.occupancy_policy {
            UnitOccupancyPolicyDto::Exclusive => UnitOccupancyPolicy::Exclusive,
            UnitOccupancyPolicyDto::FriendlyStacking => UnitOccupancyPolicy::FriendlyStacking,
        },
        units,
        cities,
        artifacts,
        interaction,
        fog,
        diplomacy,
        transport,
    )
    .map_err(|error| GameStateMappingError::new("$", error.to_string()))
}

/// Encodes the movement-complete canonical state.
#[must_use]
pub fn encode_game_state(state: &GameState) -> GameStateDto {
    GameStateDto {
        revision: state.revision().get(),
        turn: state.turn(),
        cols: state.bounds().cols(),
        rows: state.bounds().rows(),
        occupancy_policy: match state.occupancy_policy() {
            UnitOccupancyPolicy::Exclusive => UnitOccupancyPolicyDto::Exclusive,
            UnitOccupancyPolicy::FriendlyStacking => UnitOccupancyPolicyDto::FriendlyStacking,
        },
        units: state.units().iter().map(encode_unit).collect(),
        cities: state.cities().iter().map(encode_city).collect(),
        artifacts: state.artifacts().iter().map(encode_artifact).collect(),
        interaction: encode_interaction(state.interaction()),
        fog_of_war: state
            .fog_of_war()
            .players()
            .iter()
            .map(encode_fog)
            .collect(),
        diplomatic_contacts: state
            .diplomacy()
            .contacts()
            .iter()
            .map(|pair| PlayerPairDto {
                first_player_id: pair.first().as_str().to_owned(),
                second_player_id: pair.second().as_str().to_owned(),
            })
            .collect(),
        transport_network: state
            .transport_network()
            .segments()
            .iter()
            .map(encode_transport)
            .collect(),
    }
}
