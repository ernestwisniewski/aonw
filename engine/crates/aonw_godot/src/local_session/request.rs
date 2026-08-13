use aonw_content::{MapDocument, RulesetDefinition, ScenarioDefinition};
use aonw_domain::{HexCoord, PlayerId, UnitId};
use aonw_local_runtime::{
    MoveUnitRequest, OpenSession, ReachableRequest, RoutePlanRequest, UnitActionRequest,
};

pub(super) fn decode_open_request(
    map_json: &str,
    scenario_json: &str,
    actor_player_id: &str,
) -> Result<OpenSession, (&'static str, String)> {
    let map = decode_map(map_json)?;
    let ruleset = RulesetDefinition::standard().clone();
    let scenario = ScenarioDefinition::from_json(scenario_json.as_bytes(), &map, &ruleset)
        .map_err(|error| ("invalid_scenario", error.to_string()))?;
    let actor = PlayerId::new(actor_player_id)
        .map_err(|error| ("invalid_actor_player_id", error.to_string()))?;
    OpenSession::from_scenario(map, ruleset, &scenario, actor)
        .map_err(|error| ("invalid_session", error.to_string()))
}

pub(super) fn decode_map(
    map_json: &str,
) -> Result<aonw_content::MapDefinition, (&'static str, String)> {
    MapDocument::from_json(map_json.as_bytes())
        .map(|document| document.map().clone())
        .map_err(|error| ("invalid_map", error.to_string()))
}

pub(super) fn reachable_request(
    unit_id: &str,
    expected_revision: i64,
) -> Result<ReachableRequest, (&'static str, String)> {
    Ok(ReachableRequest {
        expected_revision: decode_revision(expected_revision)?,
        unit_id: decode_unit_id(unit_id)?,
    })
}

pub(super) fn route_request(
    unit_id: &str,
    target_col: i64,
    target_row: i64,
    expected_revision: i64,
) -> Result<RoutePlanRequest, (&'static str, String)> {
    Ok(RoutePlanRequest {
        expected_revision: decode_revision(expected_revision)?,
        unit_id: decode_unit_id(unit_id)?,
        target: decode_target(target_col, target_row)?,
    })
}

pub(super) fn move_request(
    unit_id: &str,
    target_col: i64,
    target_row: i64,
    expected_revision: i64,
) -> Result<MoveUnitRequest, (&'static str, String)> {
    Ok(MoveUnitRequest {
        expected_revision: decode_revision(expected_revision)?,
        unit_id: decode_unit_id(unit_id)?,
        target: decode_target(target_col, target_row)?,
    })
}

pub(super) fn unit_action_request(
    unit_id: &str,
    expected_revision: i64,
) -> Result<UnitActionRequest, (&'static str, String)> {
    Ok(UnitActionRequest {
        expected_revision: decode_revision(expected_revision)?,
        unit_id: decode_unit_id(unit_id)?,
    })
}

fn decode_revision(value: i64) -> Result<u64, (&'static str, String)> {
    u64::try_from(value).map_err(|error| ("invalid_revision", error.to_string()))
}

fn decode_unit_id(value: &str) -> Result<UnitId, (&'static str, String)> {
    UnitId::new(value).map_err(|error| ("invalid_unit_id", error.to_string()))
}

fn decode_target(col: i64, row: i64) -> Result<HexCoord, (&'static str, String)> {
    let col = i32::try_from(col).map_err(|error| ("invalid_target", error.to_string()))?;
    let row = i32::try_from(row).map_err(|error| ("invalid_target", error.to_string()))?;
    Ok(HexCoord::new(col, row))
}
