mod request;
mod response;

use aonw_content::RulesetDefinition;
use aonw_local_runtime::{LocalRuntime, RuntimeQuery, RuntimeQueryResult};
use godot::classes::{IRefCounted, RefCounted};
use godot::prelude::*;
use serde_json::json;

use crate::wire::{failure_json, success_json};

use request::{
    decode_map, decode_open_request, move_request, reachable_request, route_request,
    unit_action_request,
};
use response::{command_result_json, coordinate_json, stamp_json, unit_json, with_stamp};

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

#[cfg(test)]
mod tests;
