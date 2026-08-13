use aonw_content::{MapDefinition, MapDocument};
use aonw_contract_mapping::decode_movement_state;
use aonw_contracts::{MAX_KNOWN_UNIT_ID_COUNT, MAX_KNOWN_UNIT_IDS_JSON_BYTES};
use aonw_domain::{MovementState, PlayerId, UnitId};
use aonw_engine::{
    EngineContext, GameEngine, MoveUnitCommand, MovementPlanningView, MovementTransition,
    ReachableMovementQuery,
};
use godot::classes::{IRefCounted, RefCounted};
use godot::prelude::*;
use serde_json::{Value, json};

use crate::wire::{MovementStateWire, failure_json, success_json};

#[derive(Debug)]
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
        movement_state_json: GString,
        actor_player_id: GString,
        visibility_mode: GString,
        known_unit_ids_json: GString,
    ) -> GString {
        self.session = None;
        match decode_session(
            &map_json.to_string(),
            &movement_state_json.to_string(),
            &actor_player_id.to_string(),
            &visibility_mode.to_string(),
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
    movement_state_json: &str,
    actor_player_id: &str,
    visibility_mode: &str,
    known_unit_ids_json: &str,
) -> Result<Session, (&'static str, String)> {
    let map = MapDocument::from_json(map_json.as_bytes())
        .map(|document| document.map().clone())
        .map_err(|error| ("invalid_map", error.to_string()))?;
    let wire = MovementStateWire::parse(movement_state_json)
        .map_err(|error| ("invalid_movement_state_json", error.to_string()))?;
    let state = decode_movement_state(wire.into())
        .map_err(|error| ("invalid_movement_state", error.to_string()))?;
    let actor = PlayerId::new(actor_player_id)
        .map_err(|error| ("invalid_actor_player_id", error.to_string()))?;
    let known_unit_ids = match visibility_mode {
        "unrestricted" => {
            if !known_unit_ids_json.trim().is_empty() {
                return Err((
                    "invalid_visibility",
                    "unrestricted visibility must not provide known unit ids".to_owned(),
                ));
            }
            None
        }
        "knownUnits" => Some(
            decode_known_unit_ids(known_unit_ids_json)
                .map_err(|message| ("invalid_known_unit_ids", message))?,
        ),
        _ => {
            return Err((
                "invalid_visibility",
                "visibility mode must be unrestricted or knownUnits".to_owned(),
            ));
        }
    };
    Ok(Session {
        map,
        state,
        actor,
        known_unit_ids,
    })
}

fn decode_known_unit_ids(input: &str) -> Result<Vec<UnitId>, String> {
    if input.len() > MAX_KNOWN_UNIT_IDS_JSON_BYTES {
        return Err(format!(
            "known unit ids JSON has {} bytes; maximum is {MAX_KNOWN_UNIT_IDS_JSON_BYTES}",
            input.len()
        ));
    }
    let values = serde_json::from_str::<Vec<String>>(input).map_err(|error| error.to_string())?;
    if values.len() > MAX_KNOWN_UNIT_ID_COUNT {
        return Err(format!(
            "known unit ids has {} entries; maximum is {MAX_KNOWN_UNIT_ID_COUNT}",
            values.len()
        ));
    }
    let identifiers = values
        .into_iter()
        .map(UnitId::new)
        .collect::<Result<Vec<_>, _>>()
        .map_err(|error| error.to_string())?;
    let mut sorted = identifiers.iter().collect::<Vec<_>>();
    sorted.sort_unstable();
    if sorted.windows(2).any(|pair| pair[0] == pair[1]) {
        return Err("known unit ids must be unique".to_owned());
    }
    Ok(identifiers)
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

#[cfg(test)]
mod tests {
    use std::hint::black_box;
    use std::time::Instant;

    use aonw_contracts::{
        CURRENT_MOVEMENT_STATE_VERSION, MAX_KNOWN_UNIT_ID_COUNT, MAX_KNOWN_UNIT_IDS_JSON_BYTES,
    };
    use serde_json::json;

    use super::{decode_known_unit_ids, decode_session};

    fn map_json(cols: u16, rows: u16) -> String {
        let tiles = (0..rows)
            .flat_map(|row| {
                (0..cols).map(move |col| {
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
            "cols": cols,
            "rows": rows,
            "mapName": "session_test",
            "defaultZoom": 1.0,
            "objectives": [],
            "tiles": tiles,
        })
        .to_string()
    }

    fn state_json(schema_version: u16) -> String {
        json!({
            "schemaVersion": schema_version,
            "revision": 1,
            "turn": 1,
            "units": [{
                "id": "unit-1",
                "ownerPlayerId": "player-1",
                "kind": "warrior",
                "col": 0,
                "row": 0,
                "movementUnits": 4,
                "posture": "active",
                "movementBlocked": false,
                "queuedPath": null,
                "carriedArtifactId": null,
            }],
        })
        .to_string()
    }

    fn state_json_with_units(unit_count: usize) -> String {
        let units = (0..unit_count)
            .map(|index| {
                json!({
                    "id": format!("unit-{index}"),
                    "ownerPlayerId": "player-1",
                    "kind": "warrior",
                    "col": i32::try_from(index % 40).expect("column"),
                    "row": i32::try_from(index / 40).expect("row"),
                    "movementUnits": 6,
                    "posture": "active",
                    "movementBlocked": false,
                    "queuedPath": null,
                    "carriedArtifactId": null,
                })
            })
            .collect::<Vec<_>>();
        json!({
            "schemaVersion": CURRENT_MOVEMENT_STATE_VERSION,
            "revision": 1,
            "turn": 1,
            "units": units,
        })
        .to_string()
    }

    #[test]
    fn session_accepts_only_the_current_movement_contract() {
        decode_session(
            &map_json(5, 5),
            &state_json(CURRENT_MOVEMENT_STATE_VERSION),
            "player-1",
            "unrestricted",
            "",
        )
        .expect("current movement contract must open");

        let error = decode_session(
            &map_json(5, 5),
            &state_json(CURRENT_MOVEMENT_STATE_VERSION + 1),
            "player-1",
            "unrestricted",
            "",
        )
        .expect_err("future movement contract must fail closed");
        assert_eq!(error.0, "invalid_movement_state");
    }

    #[test]
    fn visibility_mode_is_explicit() {
        decode_session(
            &map_json(5, 5),
            &state_json(CURRENT_MOVEMENT_STATE_VERSION),
            "player-1",
            "knownUnits",
            "[]",
        )
        .expect("knownUnits may explicitly expose no units");

        let error = decode_session(
            &map_json(5, 5),
            &state_json(CURRENT_MOVEMENT_STATE_VERSION),
            "player-1",
            "",
            "",
        )
        .expect_err("missing visibility mode must fail closed");
        assert_eq!(error.0, "invalid_visibility");
    }

    #[test]
    fn known_unit_ids_are_bounded_and_unique() {
        let too_many = serde_json::to_string(
            &(0..=MAX_KNOWN_UNIT_ID_COUNT)
                .map(|index| format!("unit-{index}"))
                .collect::<Vec<_>>(),
        )
        .expect("known ids JSON");
        assert!(decode_known_unit_ids(&too_many).is_err());
        assert!(decode_known_unit_ids(r#"["unit-1","unit-1"]"#).is_err());

        let oversized = " ".repeat(MAX_KNOWN_UNIT_IDS_JSON_BYTES + 1);
        assert!(decode_known_unit_ids(&oversized).is_err());
    }

    #[test]
    #[ignore = "diagnostic wall-clock benchmark"]
    fn native_session_open_benchmark() {
        const ITERATIONS: usize = 20;
        let map = map_json(40, 30);
        let state = state_json_with_units(512);
        for _ in 0..3 {
            black_box(
                decode_session(&map, &state, "player-1", "unrestricted", "").expect("warm session"),
            );
        }

        let mut samples = Vec::with_capacity(ITERATIONS);
        for _ in 0..ITERATIONS {
            let started = Instant::now();
            let session = decode_session(&map, &state, "player-1", "unrestricted", "")
                .expect("benchmark session");
            assert_eq!(session.state.units().len(), 512);
            black_box(session);
            samples.push(started.elapsed().as_nanos());
        }
        samples.sort_unstable();
        let median = samples[samples.len() / 2];
        let p95 = samples[(samples.len() * 95 / 100).min(samples.len() - 1)];
        println!("native_session_open,1200,512,{ITERATIONS},{median},{p95}");
    }
}
