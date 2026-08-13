use aonw_content::{MapDefinition, MapDocument};
use aonw_contract_mapping::decode_movement_state;
use aonw_domain::{MovementState, PlayerId, UnitId};
use aonw_engine::{
    EngineContext, GameEngine, MoveUnitCommand, MovementPlanningView, MovementTransition,
    ReachableMovementQuery,
};
use godot::classes::{IRefCounted, RefCounted};
use godot::prelude::*;
use serde_json::{Value, json};

use crate::wire::{MovementStateWire, failure_json, success_json};

struct Session {
    map: MapDefinition,
    state: MovementState,
    actor: PlayerId,
    known_unit_ids: Option<Vec<UnitId>>,
}

impl Session {
    fn context(&self) -> EngineContext<'_> {
        let planning_view = self.known_unit_ids.as_deref().map_or_else(
            MovementPlanningView::fog_disabled,
            MovementPlanningView::known_units,
        );
        EngineContext::new(&self.actor, &self.map, planning_view)
    }
}

#[derive(GodotClass)]
#[class(base=RefCounted)]
struct AonwLocalSession {
    session: Option<Session>,
    base: Base<RefCounted>,
}

#[godot_api]
impl IRefCounted for AonwLocalSession {
    fn init(base: Base<RefCounted>) -> Self {
        Self {
            session: None,
            base,
        }
    }
}

#[godot_api]
#[allow(clippy::needless_pass_by_value)]
impl AonwLocalSession {
    #[func]
    fn open(
        &mut self,
        map_json: GString,
        legacy_map: bool,
        movement_state_json: GString,
        actor_player_id: GString,
        known_unit_ids_json: GString,
    ) -> GString {
        match decode_session(
            &map_json.to_string(),
            legacy_map,
            &movement_state_json.to_string(),
            &actor_player_id.to_string(),
            &known_unit_ids_json.to_string(),
        ) {
            Ok(session) => {
                let revision = session.state.revision();
                self.session = Some(session);
                success_json(&json!({"revision": revision}))
            }
            Err((code, message)) => failure_json(code, message),
        }
    }

    #[func]
    fn reachable_json(&self, unit_id: GString, expected_revision: i64) -> GString {
        let Some(session) = &self.session else {
            return failure_json("session_not_open", "session is not open");
        };
        let expected_revision = match u64::try_from(expected_revision) {
            Ok(value) => value,
            Err(error) => return failure_json("invalid_revision", error),
        };
        let unit_id = match UnitId::new(unit_id.to_string()) {
            Ok(value) => value,
            Err(error) => return failure_json("invalid_unit_id", error),
        };
        match GameEngine::reachable_movement(
            &session.state,
            session.context(),
            ReachableMovementQuery::new(expected_revision, &unit_id),
        ) {
            Ok(result) => success_json(&json!({
                "revision": result.revision(),
                "unitId": result.unit_id().as_str(),
                "availableMovementUnits": result.available_movement().get(),
                "tiles": result.tiles().iter().map(|tile| json!({
                    "col": tile.coordinate().col(),
                    "row": tile.coordinate().row(),
                    "costUnits": tile.cost().get(),
                    "exhaustsMovement": tile.exhausts_movement(),
                })).collect::<Vec<_>>(),
            })),
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
        let unit_id = match UnitId::new(unit_id.to_string()) {
            Ok(value) => value,
            Err(error) => return failure_json("invalid_unit_id", error),
        };
        let target_col = match i32::try_from(target_col) {
            Ok(value) => value,
            Err(error) => return failure_json("invalid_target", error),
        };
        let target_row = match i32::try_from(target_row) {
            Ok(value) => value,
            Err(error) => return failure_json("invalid_target", error),
        };
        let expected_revision = match u64::try_from(expected_revision) {
            Ok(value) => value,
            Err(error) => return failure_json("invalid_revision", error),
        };
        let Some(session) = &self.session else {
            return failure_json("session_not_open", "session is not open");
        };
        let transition = GameEngine::apply_move_unit(
            &session.state,
            session.context(),
            MoveUnitCommand::new(
                expected_revision,
                &unit_id,
                aonw_domain::HexCoord::new(target_col, target_row),
            ),
        );
        match transition {
            Ok(transition) => {
                let response = transition_json(&transition);
                self.session.as_mut().expect("checked session").state = transition.state().clone();
                success_json(&response)
            }
            Err(error) => failure_json(error.code(), error),
        }
    }
}

fn decode_session(
    map_json: &str,
    legacy_map: bool,
    movement_state_json: &str,
    actor_player_id: &str,
    known_unit_ids_json: &str,
) -> Result<Session, (&'static str, String)> {
    let map = if legacy_map {
        MapDefinition::from_legacy_json(map_json.as_bytes())
    } else {
        MapDocument::from_json(map_json.as_bytes()).map(|document| document.map().clone())
    }
    .map_err(|error| ("invalid_map", error.to_string()))?;
    let wire = serde_json::from_str::<MovementStateWire>(movement_state_json)
        .map_err(|error| ("invalid_movement_state_json", error.to_string()))?;
    let state = decode_movement_state(wire.into())
        .map_err(|error| ("invalid_movement_state", error.to_string()))?;
    let actor = PlayerId::new(actor_player_id)
        .map_err(|error| ("invalid_actor_player_id", error.to_string()))?;
    let known_unit_ids = if known_unit_ids_json.trim().is_empty() {
        None
    } else {
        let values = serde_json::from_str::<Vec<String>>(known_unit_ids_json)
            .map_err(|error| ("invalid_known_unit_ids", error.to_string()))?;
        Some(
            values
                .into_iter()
                .map(UnitId::new)
                .collect::<Result<Vec<_>, _>>()
                .map_err(|error| ("invalid_known_unit_ids", error.to_string()))?,
        )
    };
    Ok(Session {
        map,
        state,
        actor,
        known_unit_ids,
    })
}

fn transition_json(transition: &MovementTransition) -> Value {
    let event = transition.event().map(|event| {
        json!({
            "type": "UnitMoved",
            "unitId": event.unit_id().as_str(),
            "fromCol": event.from().col(),
            "fromRow": event.from().row(),
            "toCol": event.to().col(),
            "toRow": event.to().row(),
        })
    });
    let execution = transition.execution().map(|execution| {
        json!({
            "unitId": execution.unit_id().as_str(),
            "fromCol": execution.from().col(),
            "fromRow": execution.from().row(),
            "steps": execution.steps().iter().map(|step| json!({
                "col": step.coordinate().col(),
                "row": step.coordinate().row(),
                "enterCostUnits": step.enter_cost().get(),
                "cumulativeCostUnits": step.cumulative_cost().get(),
            })).collect::<Vec<_>>(),
        })
    });
    let moved_unit = transition
        .event()
        .and_then(|event| transition.state().unit(event.unit_id()));
    json!({
        "revision": transition.state().revision(),
        "noOp": transition.is_no_op(),
        "event": event,
        "execution": execution,
        "unit": moved_unit.map(|unit| json!({
            "id": unit.id().as_str(),
            "col": unit.position().col(),
            "row": unit.position().row(),
            "movementUnits": unit.movement_units().get(),
        })),
    })
}
