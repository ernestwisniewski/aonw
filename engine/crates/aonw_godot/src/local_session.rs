use aonw_content::{MapDocument, RulesetDefinition, ScenarioDefinition};
use aonw_domain::{HexCoord, PlayerId, UnitId, UnitKind, UnitPosture};
use aonw_engine::{DomainEvent, ExecutionEvidence};
use aonw_local_runtime::{
    CommandResult, LocalRuntime, MoveUnitRequest, OpenSession, PlayerUnitView, PlayerViewPatch,
    ReachableRequest, RoutePlanRequest, RuntimeQuery, RuntimeQueryResult, SessionStamp,
    UnitActionRequest,
};
use godot::classes::{IRefCounted, RefCounted};
use godot::prelude::*;
use serde_json::{Value, json};

use crate::wire::{failure_json, success_json};

#[derive(GodotClass)]
#[class(base=RefCounted)]
struct AonwLocalSession {
    runtime: LocalRuntime,
    base: Base<RefCounted>,
}

#[godot_api]
impl IRefCounted for AonwLocalSession {
    fn init(base: Base<RefCounted>) -> Self {
        Self {
            runtime: LocalRuntime::default(),
            base,
        }
    }
}

#[godot_api]
#[allow(clippy::needless_pass_by_value, clippy::unused_self)]
impl AonwLocalSession {
    #[func]
    fn capabilities_json(&self) -> GString {
        let capabilities = LocalRuntime::capabilities();
        success_json(&json!({
            "behaviorVersion": capabilities.behavior_version,
            "routePlan": capabilities.route_plan(),
            "reachable": capabilities.reachable(),
            "moveUnit": capabilities.move_unit(),
            "saveGame": capabilities.save_game(),
            "replayVerification": capabilities.replay_verification(),
            "unitActions": capabilities.unit_actions(),
        }))
    }

    #[func]
    fn open(
        &mut self,
        map_json: GString,
        scenario_json: GString,
        actor_player_id: GString,
    ) -> GString {
        let request = match decode_open_request(
            &map_json.to_string(),
            &scenario_json.to_string(),
            &actor_player_id.to_string(),
        ) {
            Ok(request) => request,
            Err((code, message)) => return failure_json(code, message),
        };
        match self.runtime.open(request) {
            Ok(stamp) => success_json(&stamp_json(stamp)),
            Err(error) => failure_json("session_open_failed", error),
        }
    }

    #[func]
    fn close(&mut self) -> GString {
        self.runtime.close();
        success_json(&json!({"closed": true}))
    }

    #[func]
    fn save_game_json(&self) -> GString {
        match self.runtime.export_save_json() {
            Ok(document) => success_json(&json!({"document": document})),
            Err(error) => failure_json("save_export_failed", error),
        }
    }

    #[func]
    fn open_save(&mut self, map_json: GString, save_json: GString) -> GString {
        let map = match decode_map(&map_json.to_string()) {
            Ok(map) => map,
            Err((code, message)) => return failure_json(code, message),
        };
        match self.runtime.open_save_json(
            map,
            RulesetDefinition::standard().clone(),
            &save_json.to_string(),
        ) {
            Ok(stamp) => success_json(&stamp_json(stamp)),
            Err(error) => failure_json("save_open_failed", error),
        }
    }

    #[func]
    fn replay_log_json(&self) -> GString {
        match self.runtime.export_replay_json() {
            Ok(document) => success_json(&json!({"document": document})),
            Err(error) => failure_json("replay_export_failed", error),
        }
    }

    #[func]
    fn verify_replay(&self, map_json: GString, replay_json: GString) -> GString {
        let map = match decode_map(&map_json.to_string()) {
            Ok(map) => map,
            Err((code, message)) => return failure_json(code, message),
        };
        match LocalRuntime::verify_replay_json(
            map,
            RulesetDefinition::standard().clone(),
            &replay_json.to_string(),
        ) {
            Ok(result) => success_json(&json!({
                "entryCount": result.entry_count,
                "finalEventOffset": result.final_event_offset,
                "finalStamp": stamp_json(result.final_stamp),
            })),
            Err(error) => failure_json("replay_verification_failed", error),
        }
    }

    #[func]
    fn snapshot_json(&self) -> GString {
        match self.runtime.snapshot() {
            Ok(snapshot) => success_json(&with_stamp(
                *snapshot.stamp(),
                json!({
                    "units": snapshot.units().iter().map(unit_json).collect::<Vec<_>>(),
                }),
            )),
            Err(error) => failure_json(error.code(), error),
        }
    }

    #[func]
    fn reachable_json(&mut self, unit_id: GString, expected_revision: i64) -> GString {
        let request = match reachable_request(&unit_id.to_string(), expected_revision) {
            Ok(request) => request,
            Err((code, message)) => return failure_json(code, message),
        };
        match self.runtime.query(&RuntimeQuery::Reachable(request)) {
            Ok(RuntimeQueryResult::Reachable(result)) => success_json(&with_stamp(
                result.stamp,
                json!({
                    "unitId": result.unit_id.as_str(),
                    "availableMovementUnits": result.available_movement.get(),
                    "tiles": result.tiles.iter().map(|tile| json!({
                        "col": tile.coordinate.col(),
                        "row": tile.coordinate.row(),
                        "costUnits": tile.cost.get(),
                        "exhaustsMovement": tile.exhausts_movement,
                    })).collect::<Vec<_>>(),
                }),
            )),
            Ok(RuntimeQueryResult::RoutePlan(_)) => {
                failure_json("invalid_runtime_response", "reachable returned route plan")
            }
            Err(error) => failure_json(error.code(), error),
        }
    }

    #[func]
    fn route_plan_json(
        &mut self,
        unit_id: GString,
        target_col: i64,
        target_row: i64,
        expected_revision: i64,
    ) -> GString {
        let request = match route_request(
            &unit_id.to_string(),
            target_col,
            target_row,
            expected_revision,
        ) {
            Ok(request) => request,
            Err((code, message)) => return failure_json(code, message),
        };
        match self.runtime.query(&RuntimeQuery::RoutePlan(request)) {
            Ok(RuntimeQueryResult::RoutePlan(result)) => success_json(&with_stamp(
                result.stamp,
                json!({
                    "unitId": result.unit_id.as_str(),
                    "target": coordinate_json(result.target),
                    "destination": coordinate_json(result.destination),
                    "totalCostUnits": result.total_cost.get(),
                    "availableMovementUnits": result.available_movement.get(),
                    "remainingMovementUnits": result.remaining_movement.get(),
                    "steps": result.steps.iter().map(|step| json!({
                        "col": step.coordinate.col(),
                        "row": step.coordinate.row(),
                        "enterCostUnits": step.enter_cost.get(),
                        "cumulativeCostUnits": step.cumulative_cost.get(),
                    })).collect::<Vec<_>>(),
                }),
            )),
            Ok(RuntimeQueryResult::Reachable(_)) => {
                failure_json("invalid_runtime_response", "route plan returned reachable")
            }
            Err(error) => failure_json(error.code(), error),
        }
    }

    #[func]
    fn move_unit_json(
        &mut self,
        unit_id: GString,
        target_col: i64,
        target_row: i64,
        expected_revision: i64,
    ) -> GString {
        let request = match move_request(
            &unit_id.to_string(),
            target_col,
            target_row,
            expected_revision,
        ) {
            Ok(request) => request,
            Err((code, message)) => return failure_json(code, message),
        };
        match self.runtime.dispatch(&request) {
            Ok(result) => success_json(&command_result_json(&result)),
            Err(error) => failure_json(error.code(), error),
        }
    }

    #[func]
    fn cancel_unit_action_json(&mut self, unit_id: GString, expected_revision: i64) -> GString {
        self.dispatch_unit_action(&unit_id, expected_revision, UnitActionMethod::Cancel)
    }

    #[func]
    fn skip_unit_turn_json(&mut self, unit_id: GString, expected_revision: i64) -> GString {
        self.dispatch_unit_action(&unit_id, expected_revision, UnitActionMethod::Skip)
    }

    #[func]
    fn fortify_unit_json(&mut self, unit_id: GString, expected_revision: i64) -> GString {
        self.dispatch_unit_action(&unit_id, expected_revision, UnitActionMethod::Fortify)
    }
}

#[derive(Clone, Copy)]
enum UnitActionMethod {
    Cancel,
    Skip,
    Fortify,
}

impl AonwLocalSession {
    fn dispatch_unit_action(
        &mut self,
        unit_id: &GString,
        expected_revision: i64,
        method: UnitActionMethod,
    ) -> GString {
        let request = match unit_action_request(&unit_id.to_string(), expected_revision) {
            Ok(request) => request,
            Err((code, message)) => return failure_json(code, message),
        };
        let result = match method {
            UnitActionMethod::Cancel => self.runtime.cancel_unit_action(&request),
            UnitActionMethod::Skip => self.runtime.skip_unit_turn(&request),
            UnitActionMethod::Fortify => self.runtime.fortify_unit(&request),
        };
        match result {
            Ok(result) => success_json(&command_result_json(&result)),
            Err(error) => failure_json(error.code(), error),
        }
    }
}

fn decode_open_request(
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

fn decode_map(map_json: &str) -> Result<aonw_content::MapDefinition, (&'static str, String)> {
    MapDocument::from_json(map_json.as_bytes())
        .map(|document| document.map().clone())
        .map_err(|error| ("invalid_map", error.to_string()))
}

fn reachable_request(
    unit_id: &str,
    expected_revision: i64,
) -> Result<ReachableRequest, (&'static str, String)> {
    Ok(ReachableRequest {
        expected_revision: decode_revision(expected_revision)?,
        unit_id: decode_unit_id(unit_id)?,
    })
}

fn route_request(
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

fn move_request(
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

fn unit_action_request(
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

fn stamp_json(stamp: SessionStamp) -> Value {
    json!({
        "behaviorVersion": stamp.behavior_version,
        "revision": stamp.revision.get(),
        "stateDigest": stamp.state_digest.to_string(),
        "mapHash": stamp.map_hash.to_string(),
        "rulesetHash": stamp.ruleset_hash.to_string(),
    })
}

fn with_stamp(stamp: SessionStamp, value: Value) -> Value {
    let mut result = stamp_json(stamp).as_object().cloned().unwrap_or_default();
    if let Value::Object(fields) = value {
        result.extend(fields);
    }
    Value::Object(result)
}

fn unit_json(unit: &PlayerUnitView) -> Value {
    json!({
        "id": unit.id().as_str(),
        "ownerPlayerId": unit.owner_player_id().as_str(),
        "kind": unit_kind_name(unit.kind()),
        "name": unit.name(),
        "col": unit.col(),
        "row": unit.row(),
        "movementUnits": unit.movement_units(),
        "posture": unit_posture_name(unit.posture()),
    })
}

fn command_result_json(result: &CommandResult) -> Value {
    with_stamp(
        result.stamp,
        json!({
            "accepted": result.is_accepted(),
            "rejection": result.rejection,
            "events": result.events.iter().map(event_json).collect::<Vec<_>>(),
            "evidence": result.evidence.as_ref().map(evidence_json),
            "viewPatch": patch_json(&result.view_patch),
        }),
    )
}

fn event_json(event: &DomainEvent) -> Value {
    match event {
        DomainEvent::UnitMoved(event) => json!({
            "type": "unitMoved",
            "unitId": event.unit_id().as_str(),
            "from": coordinate_json(event.from()),
            "to": coordinate_json(event.to()),
        }),
    }
}

fn evidence_json(evidence: &ExecutionEvidence) -> Value {
    match evidence {
        ExecutionEvidence::UnitMovement(execution) => json!({
            "type": "unitMovement",
            "unitId": execution.unit_id().as_str(),
            "from": coordinate_json(execution.from()),
            "steps": execution.steps().iter().map(|step| json!({
                "col": step.coordinate().col(),
                "row": step.coordinate().row(),
                "enterCostUnits": step.enter_cost().get(),
                "cumulativeCostUnits": step.cumulative_cost().get(),
            })).collect::<Vec<_>>(),
        }),
    }
}

fn patch_json(patch: &PlayerViewPatch) -> Value {
    json!({
        "fromRevision": patch.from_revision,
        "toRevision": patch.to_revision,
        "upsertedUnits": patch.upserted_units.iter().map(unit_json).collect::<Vec<_>>(),
        "removedUnitIds": patch.removed_unit_ids.iter().map(UnitId::as_str).collect::<Vec<_>>(),
    })
}

fn coordinate_json(coordinate: HexCoord) -> Value {
    json!({"col": coordinate.col(), "row": coordinate.row()})
}

const fn unit_kind_name(kind: UnitKind) -> &'static str {
    match kind {
        UnitKind::Commander => "commander",
        UnitKind::Warrior => "warrior",
        UnitKind::Archer => "archer",
        UnitKind::Settler => "settler",
        UnitKind::Worker => "worker",
        UnitKind::Merchant => "merchant",
        UnitKind::Scout => "scout",
        UnitKind::Spearman => "spearman",
        UnitKind::Cavalry => "cavalry",
        UnitKind::Catapult => "catapult",
        UnitKind::HeavyInfantry => "heavyInfantry",
        UnitKind::FieldCannon => "fieldCannon",
        UnitKind::Rifleman => "rifleman",
        UnitKind::Tank => "tank",
        UnitKind::ScoutShip => "scoutShip",
        UnitKind::Warship => "warship",
        UnitKind::ReconPlane => "reconPlane",
    }
}

const fn unit_posture_name(posture: UnitPosture) -> &'static str {
    match posture {
        UnitPosture::Active => "active",
        UnitPosture::Fortified => "fortified",
        UnitPosture::AutoExploring => "autoExploring",
        UnitPosture::AutoWorking => "autoWorking",
    }
}

#[cfg(test)]
mod tests {
    use std::hint::black_box;
    use std::time::Instant;

    use serde_json::json;

    use super::decode_open_request;

    fn map_json() -> String {
        let tiles = (0..5)
            .flat_map(|row| {
                (0..5).map(move |col| {
                    json!({
                        "col": col,
                        "row": row,
                        "terrains": ["grassland"],
                        "resources": [],
                        "height": 0,
                    })
                })
            })
            .collect::<Vec<_>>();
        json!({
            "schemaVersion": 1,
            "gridLayout": "oddQFlatTop",
            "cols": 5,
            "rows": 5,
            "mapName": "session-test",
            "defaultZoom": 1.0,
            "objectives": [],
            "tiles": tiles,
        })
        .to_string()
    }

    fn scenario_json() -> String {
        json!({
            "schemaVersion": 1,
            "scenarioId": "session-test",
            "mapId": "session-test",
            "rulesetId": "aonw-standard",
            "initialUnits": [{
                "id": "unit-1",
                "ownerPlayerId": "player-1",
                "kind": "commander",
                "name": "Commander",
                "col": 0,
                "row": 0,
            }],
        })
        .to_string()
    }

    fn benchmark_documents() -> (String, String) {
        let tiles = (0..30)
            .flat_map(|row| {
                (0..40).map(move |col| {
                    json!({
                        "col": col,
                        "row": row,
                        "terrains": ["grassland"],
                        "resources": [],
                        "height": 0,
                    })
                })
            })
            .collect::<Vec<_>>();
        let units = (0..512)
            .map(|index| {
                json!({
                    "id": format!("unit-{index}"),
                    "ownerPlayerId": "player-1",
                    "kind": "commander",
                    "name": "Commander",
                    "col": index % 40,
                    "row": index / 40,
                })
            })
            .collect::<Vec<_>>();
        (
            json!({
                "schemaVersion": 1,
                "gridLayout": "oddQFlatTop",
                "cols": 40,
                "rows": 30,
                "mapName": "benchmark-session",
                "defaultZoom": 1.0,
                "objectives": [],
                "tiles": tiles,
            })
            .to_string(),
            json!({
                "schemaVersion": 1,
                "scenarioId": "benchmark-session",
                "mapId": "benchmark-session",
                "rulesetId": "aonw-standard",
                "initialUnits": units,
            })
            .to_string(),
        )
    }

    #[test]
    fn adapter_open_contract_is_strict_and_current() {
        decode_open_request(&map_json(), &scenario_json(), "player-1")
            .expect("current contracts must open");
        let future = scenario_json().replace("\"schemaVersion\":1", "\"schemaVersion\":2");
        let error = decode_open_request(&map_json(), &future, "player-1")
            .expect_err("future contract must fail closed");
        assert_eq!(error.0, "invalid_scenario");
    }

    #[test]
    #[ignore = "diagnostic wall-clock benchmark"]
    fn native_session_open_benchmark() {
        const ITERATIONS: usize = 20;
        let (map, scenario) = benchmark_documents();
        for _ in 0..3 {
            black_box(
                decode_open_request(&map, &scenario, "player-1").expect("warm native session"),
            );
        }
        let mut samples = Vec::with_capacity(ITERATIONS);
        for _ in 0..ITERATIONS {
            let started = Instant::now();
            black_box(
                decode_open_request(&map, &scenario, "player-1").expect("benchmark native session"),
            );
            samples.push(started.elapsed().as_nanos());
        }
        samples.sort_unstable();
        let median = samples[samples.len() / 2];
        let p95 = samples[(samples.len() * 95 / 100).min(samples.len() - 1)];
        println!("native_session_open,1200,512,{ITERATIONS},{median},{p95}");
    }
}
