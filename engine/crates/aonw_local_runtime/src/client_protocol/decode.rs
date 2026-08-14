use aonw_content::{MapDefinition, MapDocument, RulesetDefinition, ScenarioDefinition};
use aonw_contracts::client::{ClientCommandDto, ClientQueryDto};
use aonw_domain::{HexCoord, PlayerId, UnitId};

use crate::{
    MoveUnitRequest, OpenSession, ReachableRequest, RoutePlanRequest, RuntimeQuery,
    UnitActionRequest,
};

use super::ClientDecodeError;

pub(super) enum DecodedCommand {
    Move(MoveUnitRequest),
    Cancel(UnitActionRequest),
    Skip(UnitActionRequest),
    Fortify(UnitActionRequest),
}

pub(super) fn open_session(
    map_document: &str,
    scenario_document: &str,
    actor_player_id: &str,
) -> Result<OpenSession, ClientDecodeError> {
    let map = map(map_document)?;
    let ruleset = RulesetDefinition::standard().clone();
    let scenario = ScenarioDefinition::from_json(scenario_document.as_bytes(), &map, &ruleset)
        .map_err(|error| ClientDecodeError::new("invalid_scenario", error))?;
    let actor = PlayerId::new(actor_player_id)
        .map_err(|error| ClientDecodeError::new("invalid_actor_player_id", error))?;
    OpenSession::from_scenario(map, ruleset, &scenario, actor)
        .map_err(|error| ClientDecodeError::new("invalid_session", error))
}

pub(super) fn map(document: &str) -> Result<MapDefinition, ClientDecodeError> {
    MapDocument::from_json(document.as_bytes())
        .map(|document| document.map().clone())
        .map_err(|error| ClientDecodeError::new("invalid_map", error))
}

pub(super) fn query(query: ClientQueryDto) -> Result<RuntimeQuery, ClientDecodeError> {
    match query {
        ClientQueryDto::Reachable {
            expected_revision,
            unit_id,
        } => Ok(RuntimeQuery::Reachable(ReachableRequest {
            expected_revision,
            unit_id: decode_unit_id(unit_id)?,
        })),
        ClientQueryDto::RoutePlan {
            expected_revision,
            unit_id,
            target,
        } => Ok(RuntimeQuery::RoutePlan(RoutePlanRequest {
            expected_revision,
            unit_id: decode_unit_id(unit_id)?,
            target: HexCoord::new(target.col, target.row),
        })),
    }
}

pub(super) fn command(command: ClientCommandDto) -> Result<DecodedCommand, ClientDecodeError> {
    match command {
        ClientCommandDto::MoveUnit {
            expected_revision,
            unit_id,
            target,
        } => Ok(DecodedCommand::Move(MoveUnitRequest {
            expected_revision,
            unit_id: decode_unit_id(unit_id)?,
            target: HexCoord::new(target.col, target.row),
        })),
        ClientCommandDto::CancelUnitAction {
            expected_revision,
            unit_id,
        } => unit_action(expected_revision, unit_id).map(DecodedCommand::Cancel),
        ClientCommandDto::SkipUnitTurn {
            expected_revision,
            unit_id,
        } => unit_action(expected_revision, unit_id).map(DecodedCommand::Skip),
        ClientCommandDto::FortifyUnit {
            expected_revision,
            unit_id,
        } => unit_action(expected_revision, unit_id).map(DecodedCommand::Fortify),
    }
}

fn unit_action(
    expected_revision: u64,
    unit_id: String,
) -> Result<UnitActionRequest, ClientDecodeError> {
    Ok(UnitActionRequest {
        expected_revision,
        unit_id: decode_unit_id(unit_id)?,
    })
}

fn decode_unit_id(value: String) -> Result<UnitId, ClientDecodeError> {
    UnitId::new(value).map_err(|error| ClientDecodeError::new("invalid_unit_id", error))
}
